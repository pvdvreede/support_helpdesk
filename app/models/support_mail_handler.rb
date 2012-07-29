
class SupportMailHandler < ActionMailer::Base
  default :from => "support@yourdomain.com"
  append_view_path("#{Rails.root}/plugins/support_helpdesk/app/views")

	def self.receive(message, options={})
    # create the issue from the message
    email = Support::Email.new message

    tracker = Tracker.where(:name => "Ticket")[0]
    issue = Issue.new :subject => email.subject, :tracker => tracker, \
                      :project_id => 1, :description => "Ticket generated from attached email.", \
                      :author_id => 1, :status_id => 1, :assigned_to_id => 1
    replyfield = IssueCustomField.where(:name => "Reply Address")[0]
    replyaddressfield = CustomValue.new :customized_id => issue, \
                                        :custom_field_id => replyfield, \
                                        :value => email.from

    # send attachment to redmine
    self.attach_email(issue, email, "#{email.from}_#{email.to}.msg")

    # send email back to ticket creator
    SupportMailHandler.ticket_created(issue, email.from).deliver
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