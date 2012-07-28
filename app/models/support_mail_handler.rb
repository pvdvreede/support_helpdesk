
class SupportMailHandler < ActionMailer::Base

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
    mail :to => to, \
         :subject => "Support ticket"
  end

  def ticket_closed(issue, to)
    @issue = issue
    ::Rails.logger.debug "Sending closing support email..."
    mail :to => to,
         :support => "Support ticket closed"
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