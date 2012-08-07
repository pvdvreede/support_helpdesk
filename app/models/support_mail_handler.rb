
class SupportMailHandler
  
	def receive(message, options={})
    begin     
      self.route_email message    
    rescue Exception => e
      Support.log_error "There was an error #{e} processing message:\n#{message}"
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
      # tell POP3 to not delete the email,cause it might not be for us
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
    # TODO put issue creation inside transaction for atomicity

    # get the assignee and update the round robin item
    last_assignee = support.last_assigned_user_id || 0
    this_assignee = get_assignee(support.assignee_group_id, last_assignee)

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

    issue = Issue.new({:subject => email.subject, 
                      :tracker_id => support.tracker_id,
                      :project_id => project_id,
                      :description => body, 
                      :author_id => support.author_id, 
                      :status_id => support.new_status_id, 
                      :assigned_to_id => this_assignee})
    support.last_assigned_user_id = this_assignee
    support.save
    issue.support_helpdesk_setting = support
    issue.reply_email = email.from[0]
    issue.support_type = support.name

    if not issue.save
      Support.log_error "Error saving issue because #{issue.errors.full_messages.join("\n")}"
    end

    # send attachment to redmine
    SupportMailHandler.attach_email(
      issue, 
      email.encoded, 
      "#{email.from[0]}_#{email.to[0]}.eml",
      "Email issue was created from."
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
            "Ticket created email sent to user."
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
    return true
  end

  def update_issue(issue_id, email)
    issue = Issue.find issue_id

    # attach the email to the issue
    SupportMailHandler.attach_email(
      issue, 
      email.encoded, 
      "#{email.from[0]}_#{email.to[0]}.eml",
      "Email from #{email.from[0]}."
    )

    # add a note to the issue with email body
    journal = Journal.new
    journal.notes = "Email received from #{email.from[0]} at #{Time.now.to_s} and is attached."
    journal.user_id = issue.support_helpdesk_setting.author_id
    issue.journals << journal
    if not issue.save
      Support.log_error "Could not save issue #{issue.errors.full_messages.join("\n")}"
      return false
    end

    # update processed time
    issue.support_helpdesk_setting.last_processed = Time.now.utc

    return true
  end

  # use round robin
  def get_assignee(group_id, last_id)
    users = Group.find(group_id).users.order("id")
    ::Rails.logger.debug "There are #{users.count} users in the group."
    user_count = users.count
    return if user_count == 0
    return users[0].id if user_count == 1
    return users[0].id if last_id == 0 
    users.each_with_index do |u, i|
      if u.id == last_id
        if i+1 == user_count
          return users[0].id
        else
          return users[i+1].id
        end
      end
    end
  end

  def get_project_from_email_domain(domain, field_id, default_project_id)
    # search for the project
    projects = Project.joins(:custom_values).
                       where("#{CustomValue.table_name}.custom_field_id = ?", field_id).
                       where("#{CustomValue.table_name}.value = ?", domain)
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