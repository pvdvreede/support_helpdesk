
class SupportMailHandler < ActionMailer::Base
	def self.receive(message, options={})
    # create the issue from the message
    # get message details
    from = (message =~ /^[Ff]rom:\s*(.*)$/ ? $1 : '').strip
    to = (message =~ /^[Tt]o:\s*(.*)$/ ? $1 : '').strip
    subject = (message =~ /^[Ss]ubject:\s*(.*)$/ ? $1 : '').strip

    tracker = Tracker.where(:name => "Ticket")[0]
    issue = Issue.new :subject => subject, :tracker => tracker, \
                      :project_id => 1, :description => "nothing yet", \
                      :author_id => 1, :status_id => 1, :assigned_to_id => 1
    issue.save
    replyfield = IssueCustomField.where(:name => "Reply Address")[0]
    replyaddressfield = CustomValue.new :customized => issue, \
                                        :custom_field => replyfield, \
                                        :value => from
    replyaddressfield.save

    # send attachment to redmine
    filename = self.attach_email(issue, message, "#{from}_#{to}.msg")
	end

  def logger
    ::Rails.logger
  end

  def ticket_created(issue, to)
    @issue = issue
    mail :to => to, \
         :subject => "Support ticket"
  end

  private
  def self.attach_email(issue, email, filename)
    attachment = Attachment.new(:file => email)
    attachment.author = User.where(:id => 1)[0]
    attachment.content_type = "ms/outlook"
    attachment.filename = filename
    attachment.container = issue
    attachment.save
  end
end