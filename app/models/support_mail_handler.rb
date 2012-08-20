# Support Helpdesk - Redmine plugin
# Copyright (C) 2012 Paul Van de Vreede
#
# This file is part of Support Helpdesk.
#
# Support Helpdesk is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Support Helpdesk is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Support Helpdesk.  If not, see <http://www.gnu.org/licenses/>.


class SupportMailHandler 
  def receive(message, options={})
    begin
      return self.route_email message
    rescue Exception => e
      Support.log_error "There was an error #{e} processing message:\n#{e.backtrace}\n\n#{message}"
      return false
    end
  end

  def route_email(email)
    status = false

    # otherwise create a new ticket if there is a support setting for it
    supports = find_support_from_email email

    # check if it is for a current issue first
    id = check_issue_exists(email)
    ActiveRecord::Base.transaction do
      if id != false
        status = update_issue id, email
      else
        # if none than ignore the email
        if supports.empty?
          Support.log_info "No active support setups match the email address: #{email.to[0]}."
          # tell POP3 to not delete the email, cause it might not be for us
          return false
        end

        # check if there is ignore email and this email is one of them
        if supports[0].is_ignored_email_domain(email) == true
          Support.log_info "Email from #{email.from[0]} is on the ignored domain list. Message ignored and will be deleted."
          return true
        end

        status = self.create_issue(supports[0], email)
      end

      # update last processed for support and return status
      if status == true and supports[0] != nil
        supports[0].last_processed = Time.now.utc
        supports[0].save
      end
    end
    return status
  end

  def find_support_from_email(email)
    # join all possible emails address into one array for looping
    emails = email.to.to_a + email.cc.to_a + email.bcc.to_a
    where_string = ""
    where_array = []
    emails.each do |e|
      where_string += "LOWER(to_email_address) LIKE ?"
      where_string += " OR " unless emails.last == e
      where_array.push "%#{e.downcase}%"
    end

    # pop in the where clause over the top of the values for an escapable where array
    where_array.unshift where_string

    SupportHelpdeskSetting.active.where(where_array)
  end

  def check_issue_exists(email)
    # see if this is an update to an existing ticket based on subject
    subject = email.subject
    id = (subject =~ /Ticket #([0-9]*)/ ? $1 : false)
  end

  def create_issue(support, email)   
    # if project_id is nil then get id from domain
    if support.email_domain_custom_field_id != nil
      project_id = get_project_from_email_domain(
        email.from[0].split("@")[1],
        support.email_domain_custom_field_id,
        support.project_id
      )
    else
      project_id = support.project_id
    end

    issue = Issue.new(
      :subject => email.subject, 
      :tracker_id => support.tracker_id,
      :project_id => project_id,
      :description => SupportMailHandler.get_email_body_text(email), 
      :author_id => support.author_id, 
      :status_id => support.new_status_id, 
      :assigned_to_id => support.assignee_group_id,
      :start_date => Time.now.utc
    )
    issue.support_helpdesk_setting = support
    issue.reply_email = support.get_email_reply_string(email)
    issue.support_type = support.name

    unless issue.save
      Support.log_error "Error saving issue because #{issue.errors.full_messages.join("\n")}"
      raise ActiveRecord::Rollback
    end

    # send attachment to redmine
    attachment_client_id = SupportMailHandler.attach_email(
      issue, 
      email, 
      "#{email.from[0]}_#{email.to[0]}.eml",
      "Original Email Sent from Customer.",
      support.author_id
    )

    SupportMailHandler.create_email_message_id(issue, email, support.id, attachment_client_id)

    # send email back to ticket creator if it has been request
    if support.send_created_email_to_user
      SupportMailHandler.send_email(issue, email, support) do 
        mail = SupportHelpdeskMailer.ticket_created(issue, issue.reply_email).deliver
      end
    end
    
    return true
  end

  def update_issue(issue_id, email)
    begin
      issue = Issue.find(issue_id)
    rescue ActiveRecord::RecordNotFound
      # make sure there is an issue with that number or else return false to ignore the email
      return false
    end

    if not issue.save
      Support.log_error "Could not save issue #{issue.errors.full_messages.join("\n")}"
      raise ActiveRecord::Rollback
    end

    # attach the email to the issue
    attachment_id = SupportMailHandler.attach_email(
      issue, 
      email, 
      "#{email.from[0]}_#{email.to[0]}.eml",
      "Email from #{email.from[0]}.",
      issue.support_helpdesk_setting.author_id
    )

    SupportMailHandler.create_email_message_id(issue, email, issue.support_helpdesk_setting.id, attachment_id)
    
    return true
  end

  def get_project_from_email_domain(domain, field_id, default_project_id)
    # search for the project
    projects = Project.joins(:custom_values). \
                       where("#{CustomValue.table_name}.custom_field_id = ?", field_id). \
                       where("LOWER(#{CustomValue.table_name}.value) like ?", "%#{domain.downcase}%")
    return default_project_id if projects.empty? or projects.count > 1
    return projects[0].id
  end

  def self.attach_email(issue, email, filename, description, author_id)
    #add attachment
    attachment = Attachment.new(:file => email.encoded)
    attachment.author = User.find author_id
    attachment.content_type = "message/rfc822"
    attachment.filename = filename
    attachment.container = issue
    attachment.description = description if description
    if not attachment.save
      raise ActiveRecord::Rollback
    end

    # add a note to the issue with email body
    journal = Journal.new
    journal.notes = "Email at #{Time.now.strftime("%d %b %Y %I:%M:%S %p")}:\n\n#{SupportMailHandler.get_email_body_text(email)}"
    journal.user_id = issue.support_helpdesk_setting.author_id
    issue.journals << journal

    # add detail to specify which attachment is the email
    detail = JournalDetail.new
    detail.journal_id = journal.id
    detail.property = "attachment"
    detail.prop_key = attachment.id
    detail.value = filename

    unless detail.save
      Support.log_error "Error saving journal detail because #{issue.errors.full_messages.join("\n")}"
      raise ActiveRecord::Rollback
    end

    attachment.id
  end

  def self.create_email_message_id(issue, email, support_id, attachment_id)
    # create the message id from the email and relate it to the issue and support
    support_message_id = IssuesSupportMessageId.create!(
      :issue_id => issue.id,
      :support_helpdesk_setting_id => support_id,
      :message_id => email.message_id,
      :attachment_id => attachment_id
    )

    # get the parent and add to it
    if email.reply_to.nil? == false
      parent_message = IssuesSupportMessageId.where(:message_id => email.reply_to)[0]
    elsif email.references.nil? == false
      parent_message = IssuesSupportMessageId.where(:message_id => email.references)[0]
    end
    support_message_id.move_to_child_of(parent_message) unless parent_message.nil?
    unless support_message_id.save
      Support.log_error "Error saving support message id because #{issue.errors.full_messages.join("\n")}"
      raise ActiveRecord::Rollback
    end
  end

  def self.get_email_body_text(email)
    begin
      html_encode = false

      # handle single part emails
      unless email.multipart?
        part = email

        if email.content_type.include? "text/html"
          raise TypeError.new "Email is html only."
        end
      else
        if email.text_part.nil? == false
          part = email.text_part
        elsif email.html_emailpart.nil? == false
          raise TypeError.new "Email only has html part."
          #part = email.html_part
          #html_encode = true
        else
          raise TypeError.new "Email does not have text or html part."
        end
      end

      case part.body.encoding
      when "base64"
        body = Base64.decode64(part.body.raw_source)
      else
        body = part.body.raw_source
      end

      if html_encode
        body = CGI.unescapeHTML(body)
      end
    rescue => ex
      Support.log_error "Exception trying to load email body so using static text: #{ex}"
      body = "Could not decode email body. Email body in attached email."
    end
    body
  end

  def self.send_email(issue, email, support, &block)
    email_status = ""
    begin
      mail = block.call
    rescue Exception => e
      Support.log_error "Error in sending email for #{issue.id}: #{e}\n#{e.backtrace.join("\n")}"
      email_status = "Error sending ticket creation email, email was *NOT* sent."
    else
      email_status = "Emailed ticket creation to #{email.from[0]} at #{Time.now.strftime("%d %b %Y %I:%M:%S %p")}."

      filename = "#{mail.from}_#{mail.to}.eml"

      # save the email sent for our records
      attachment_id = SupportMailHandler.attach_email(
          issue,
          mail,
          filename,
          "Ticket created email sent to Customer.",
          support.author_id
        )

      SupportMailHandler.create_email_message_id(issue, mail, support.id, attachment_id)

    end

  end
end