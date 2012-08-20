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
      emailer = Support::Emailer.new message
      return self.route_email emailer
    rescue Exception => e
      Support.log_error "There was an error #{e} processing message:\n#{e.backtrace}\n\n#{message}"
      return false
    end
	end

  def route_email(emailer)
    status = false

    # otherwise create a new ticket if there is a support setting for it
    support = emailer.find_support

    # check if it is for a current issue first
    id = self.check_issue_exists(emailer.email)
    ActiveRecord::Base.transaction do
      if id != false
        status = update_issue(id, emailer)
      else
        # if none than ignore the email
        if support.nil?
          Support.log_info "No active support setups match the email address: #{emailer.email.to[0]}."
          # tell POP3 to not delete the email, cause it might not be for us
          return false
        end

        # check if there is ignore email and this email is one of them
        if support.is_ignored_email_domain(emailer.email)
          Support.log_info "Email from #{emailer.email.from[0]} is on the ignored domain list. Message ignored and will be deleted."
          return true
        end

        status = self.create_issue(support, emailer)
      end

      # update last processed for support and return status
      if status == true and support != nil
        support.last_processed = Time.now.utc
        support.save
      end
    end
    return status
  end

  def check_issue_exists(email)
    # see if this is an update to an existing ticket based on subject
    subject = email.subject
    id = (subject =~ /Ticket #([0-9]*)/ ? $1 : false)
  end

  def create_issue(support, emailer)   
    # if project_id is nil then get id from domain
    if support.email_domain_custom_field_id != nil
      project_id = get_project_from_email_domain(
        emailer.from_domain,
        support.email_domain_custom_field_id,
        support.project_id
      )
    else
      project_id = support.project_id
    end

    issue = Issue.new(
      :subject => emailer.email.subject, 
      :tracker_id => support.tracker_id,
      :project_id => project_id,
      :description => emailer.get_email_body_text, 
      :author_id => support.author_id, 
      :status_id => support.new_status_id, 
      :assigned_to_id => support.assignee_group_id,
      :start_date => Time.now.utc
    )
    issue.support_helpdesk_setting = support
    issue.reply_email = emailer.get_email_reply_string(support)
    issue.support_type = support.name

    unless issue.save
      Support.log_error "Error saving issue because #{issue.errors.full_messages.join("\n")}"
      raise ActiveRecord::Rollback
    end

    emailer.attach_email(
      issue,
      "Original email from client."
    )

    # send email back to ticket creator if it has been requested
    if support.send_created_email_to_user
      emailer.send_email(issue) do 
        SupportHelpdeskMailer.ticket_created(issue, issue.reply_email).deliver
      end
    end
    
    return true
  end

  def update_issue(issue_id, emailer)
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

    emailer.attach_email(
      issue,
      "Email received from #{emailer.email.from[0].to_s.downcase}."
    )
    
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

end