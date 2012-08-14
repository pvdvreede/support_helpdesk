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
      self.route_email message    
    rescue Exception => e
      Support.log_error "There was an error #{e} processing message:\n#{e.backtrace}\n\n#{message}"
      return false
    end
	end

  def route_email(email)
    # check if it is for a current issue first
    id = check_issue_exists(email)
    if (id != false)
      return update_issue id, email
    end

    # otherwise create a new ticket if there is a support setting for it
    supports = SupportHelpdeskSetting.where("LOWER(to_email_address) LIKE ?", "%#{email.to[0].downcase}%") \
                                     .where(:active => true)

    # if none than ignore the email
    unless supports.count > 0
      Support.log_info "No active support setups match the email address: #{email.to[0]}."
      # tell POP3 to not delete the email, cause it might not be for us
      return false
    end

    return self.create_issue(supports[0], email)
  end

  def check_issue_exists(email)
    # see if this is an update to an existing ticket based on subject
    subject = email.subject
    id = (subject =~ /Ticket #([0-9]*)/ ? $1 : false)
  end

  def create_issue(support, email)

    ActiveRecord::Base.transaction do
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

      begin
        body = email.text_part.body.raw_source
      rescue => ex
        Support.log_error "Exception trying to load email body so using static text: #{ex}"
        body = "Ticket generated from attached email."
      end

      issue = Issue.new(
        :subject => email.subject, 
        :tracker_id => support.tracker_id,
        :project_id => project_id,
        :description => body, 
        :author_id => support.author_id, 
        :status_id => support.new_status_id, 
        :assigned_to_id => support.assignee_group_id,
        :start_date => Time.now.utc
      )
      issue.support_helpdesk_setting = support
      issue.reply_email = email.from[0]
      issue.support_type = support.name

      if not issue.save
        Support.log_error "Error saving issue because #{issue.errors.full_messages.join("\n")}"
        raise ActiveRecord::Rollback
      end

      # send attachment to redmine
      SupportMailHandler.attach_email(
        issue, 
        email.encoded, 
        "#{email.from[0]}_#{email.to[0]}.eml",
        "Original Email Sent from Customer."
       )

      # send email back to ticket creator if it has been request
      if support.send_created_email_to_user
        begin
          mail = SupportHelpdeskMailer.ticket_created(issue, email.from[0]).deliver
        rescue Exception => e
          Support.log_error "Error in sending email for #{issue.id}: #{e}\n#{e.backtrace.join("\n")}"
          email_status = "Error sending ticket creation email, email was *NOT* sent."
        else
          email_status = "Emailed ticket creation to #{email.from[0]} at #{Time.now.to_s}."

          # save the email sent for our records
          SupportMailHandler.attach_email(
              issue,
              mail.encoded,
              "#{mail.from}_#{mail.to}.eml",
              "Ticket created email sent to Customer."
            )
        end

        # add a note to the issue so we know the closing email was sent
        journal = Journal.new
        journal.notes = email_status
        journal.user_id = support.author_id
        issue.journals << journal
      end

      # update the last run for the support
      support.last_processed = Time.now.utc
      support.save
    end
    return true
  end

  def update_issue(issue_id, email)
    issue = Issue.find issue_id

    ActiveRecord::Base.transaction do
      # add a note to the issue with email body
      journal = Journal.new
      journal.notes = "Email received from #{email.from[0]} at #{Time.now.to_s} and is attached."
      journal.user_id = issue.support_helpdesk_setting.author_id
      issue.journals << journal
      if not issue.save
        Support.log_error "Could not save issue #{issue.errors.full_messages.join("\n")}"
        raise ActiveRecord::Rollback
      end

      # update processed time
      issue.support_helpdesk_setting.last_processed = Time.now.utc

      # attach the email to the issue
      SupportMailHandler.attach_email(
        issue, 
        email.encoded, 
        "#{email.from[0]}_#{email.to[0]}.eml",
        "Email from #{email.from[0]}."
      )
    end
    return true
  end

  def get_project_from_email_domain(domain, field_id, default_project_id)
    # search for the project
    projects = Project.joins(:custom_values). \
                       where("#{CustomValue.table_name}.custom_field_id = ?", field_id). \
                       where("LOWER(#{CustomValue.table_name}.value) like ?", "%#{domain.downcase}%")
    return default_project_id if projects.empty?
    return projects[0].id
  end

  def self.attach_email(issue, email_string, filename, description=nil)
    attachment = Attachment.new(:file => email_string)
    attachment.author = User.where(:id => 1)[0]
    attachment.content_type = "message/rfc822"
    attachment.filename = filename
    attachment.container = issue
    attachment.description = description if description
    attachment.save
  end

end