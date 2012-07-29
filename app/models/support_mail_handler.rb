
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
    ::Rails.logger.debug "Creating issue for message..."
    issue = Issue.new(:subject => email.subject, 
                      :tracker_id => support.tracker_id, 
                      :project_id => support.project_id, 
                      :description => "Ticket generated from attached email.", 
                      :author_id => support.author_id, 
                      :status_id => support.new_status_id, 
                      :assigned_to_id => SupportMailHandler.get_assignee(support.assignee_group_id))
    issue.save
    replyaddressfield = CustomValue.new(:customized_id => issue.id,
                                        :custom_field_id => support.reply_email_custom_field_id,
                                        :value => email.from)
    typefield = CustomValue.new(:customized_id => issue.id,
                                :custom_field_id => support.type_custom_field_id,
                                :value => support.name)   
    # send attachment to redmine
    SupportMailHandler.attach_email(issue, email, "#{email.from}_#{email.to_email}.msg")

    # send email back to ticket creator
    SupportMailHandler.ticket_created(issue, email.from).deliver if support.send_created_email_to_user
  end

  def get_assignee(group_id)
    return 1
  end

  def ticket_created(issue, to)
    @issue = issue
    ::Rails.logger.debug "Sending return support email..."
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
  def self.attach_email(issue, email, filename)
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