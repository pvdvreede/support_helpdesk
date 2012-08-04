
class SupportMailHandler
  
	def receive(message, options={})
    # create the issue from the message
    email = Support::Email.new message

    self.route_email email
	end

  def route_email(email)
    supports = SupportHelpdeskSetting.where("to_email_address LIKE ?", "%#{email.to_email}%")
    # if none than ignore the email
    unless supports.count > 0
      ::Rails.logger.debug "No support setups match the email address: #{email.to}."
      return
    end

    supports.each do |support|
      self.create_issue(support, email)
    end
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
    SupportMailHandler.attach_email(issue, email, "#{email.from}_#{email.to_email}.msg")

    # send email back to ticket creator
    SupportHelpdeskMailer.ticket_created(issue, email.from).deliver if support.send_created_email_to_user
  end

  # use round robin
  def get_assignee(group_id, last_id)
    users = Group.find(group_id).users.order("id")
    ::Rails.logger.debug "There are #{users.count} users in the group."
    user_count = users.count
    next_id = 0 if user_count == 0
    next_id = users[0].id if user_count == 1
    next_id = users[0].id if last_id == 0
    if user_count > 1
      users.each_with_index do |u, i|
        if u.id == last_id
          if i+1 == user_count
            next_id = users[0].id
          else
            next_id = users[i+1].id
          end
        end
      end
    end
    ::Rails.logger.debug "Returning user #{next_id} as the next assignee."
    next_id
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