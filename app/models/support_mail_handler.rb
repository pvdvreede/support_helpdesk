
class SupportMailHandler < ActionMailer::Base
  default :from => "support@yourdomain.com"
  append_view_path("#{Rails.root}/plugins/support_helpdesk/app/views")

	def self.receive(message, options={})
    # create the issue from the message
    email = Support::Email.new message

    SupportMailHandler.route_email email
	end

  def route_email(email)
    supports = SupportHelpdeskSetting.where("to_email_address LIKE ?", "%#{email.to_email}%")
    # if none than ignore the email
    unless supports.count > 0
      ::Rails.logger.debug "No support setups match the email address: #{email.to}."
      return
    end

    supports.each do |support|
      SupportMailHandler.create_issue(support, email)
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
    replyaddressfield = CustomValue.new({:custom_field_id => support.reply_email_custom_field_id,
                                        :value => email.from})
    typefield = CustomValue.new({:custom_field_id => support.type_custom_field_id,
                                :value => support.name}) 

    issue.custom_field_values << replyaddressfield
    issue.custom_field_values << typefield
    

    # send attachment to redmine
    attach_email(issue, email, "#{email.from}_#{email.to_email}.msg")

    # send email back to ticket creator
    SupportMailHandler.ticket_created(issue, email.from).deliver if support.send_created_email_to_user
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

  def ticket_created(issue, to)
    @issue = issue
    ::Rails.logger.debug "Sending ticket creation support email..."
    mail(:to => to, 
         :subject => "Support ticket", 
         :template_name => "ticket_created", 
         :template_path => 'support_mail_handler') do |format|
      format.html
    end
  end

  def ticket_closed(issue, to)
    @issue = issue
    ::Rails.logger.debug "Sending closing support email..."
    mail(:to => to, 
         :subject => "Support ticket closed", 
         :template_name => "ticket_closed", 
         :template_path => 'support_mail_handler') do |format|
      format.html
    end
  end

  private
  def attach_email(issue, email, filename)
    attachment = Attachment.new(:file => email.original)
    attachment.author = User.where(:id => 1)[0]
    attachment.content_type = "ms/outlook"
    attachment.filename = filename
    attachment.container = issue
    attachment.save
  end

  def self.logger
    ::Rails.logger
  end
end