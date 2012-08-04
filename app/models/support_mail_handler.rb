
class SupportMailHandler
  
	def receive(message, options={})
    # create the issue from the message
    email = Support::Email.new message

    # TODO add return value of outcome so emailer knows whether to delete the email or not
    self.route_email email    
	end

  def route_email(email)
    # check if it is for a current issue first
    id = check_issue_exists(email)
    if (id != false)
      return update_issue id, email
    end

    # otherwise create a new ticket if there is a support setting for it
    supports = SupportHelpdeskSetting.where("to_email_address LIKE ?", "%#{email.to_email}%")
    # if none than ignore the email
    unless supports.count > 0
      ::Rails.logger.debug "No support setups match the email address: #{email.to}."
      return true
    end

    supports.each do |support|
      self.create_issue(support, email)
    end
  end

  def check_issue_exists(email)
    # see if this is an update to an existing ticket based on subject
    subject = email.subject
    id = (subject =~ /Ticket #([0-9]*)/ ? $1 : false)
  end

  def create_issue(support, email)
    # TODO put issue creation inside transaction for atomicity

    ::Rails.logger.debug "Creating issue for message..."
    # get the assignee and update the round robin item
    last_assignee = support.last_assigned_user_id || 0
    this_assignee = get_assignee(support.assignee_group_id, last_assignee)
    ::Rails.logger.debug "The assigned is id #{this_assignee}."
    issue = Issue.new({:subject => email.subject, 
                      :tracker_id => support.tracker_id, 
                      :project_id => support.project_id, 
                      :description => "Ticket generated from attached email.", 
                      :author_id => support.author_id, 
                      :status_id => support.new_status_id, 
                      :assigned_to_id => this_assignee})
    support.last_assigned_user_id = this_assignee
    support.save
    issue.support_helpdesk_setting = support
    issue.reply_email = email.from
    issue.support_type = support.name

    if not issue.save
      ::Rails.logger.error "Error saving issue because #{issue.errors.full_messages.join("\n")}"
    end

    # send attachment to redmine
    SupportMailHandler.attach_email(issue, 
                                    email, 
                                    "#{email.from_email}_#{email.to_email}.msg",
                                    "Email issue was created from."
                                    )

    # send email back to ticket creator
    SupportHelpdeskMailer.ticket_created(issue, email.from).deliver if support.send_created_email_to_user
  end

  def update_issue(issue_id, email)
    issue = Issue.find issue_id

    # attach the email to the issue
    SupportMailHandler.attach_email(issue, 
                                    email, 
                                    "#{email.from_email}_#{email.to_email}.msg",
                                    "Email from #{email.from}."
                                    )

    # add a note to the issue with email body
    journal = Journal.new
    journal.notes = "Email received from #{email.from} at #{Time.now.to_s} and is attached."
    journal.user_id = issue.support_helpdesk_setting.author_id
    issue.journals << journal
    if not issue.save
      ::Rails.logger.error "Could not save issue #{issue.errors.full_messages.join("\n")}"
      return false
    end
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

  def self.attach_email(issue, email, filename, description=nil)
    attachment = Attachment.new(:file => email.original)
    attachment.author = User.where(:id => 1)[0]
    attachment.content_type = "application/msoutlook"
    attachment.filename = filename
    attachment.container = issue
    attachment.description = description if description
    attachment.save
  end

  def self.logger
    ::Rails.logger
  end
end