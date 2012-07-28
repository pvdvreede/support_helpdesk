
class SupportMailHandler < ActionMailer::Base
	def self.receive(message, options={})
    # create the issue from the message
    # get message details
    from = (message =~ /^[Ff]rom:\s*([a-zA-Z0-9\s<>@\.,]*)$/ ? $1 : '').strip
    to = (message =~ /^[Tt]o:\s*([a-zA-Z0-9\s<>@\.,]*)$/ ? $1 : '').strip
    subject = (message =~ /^[Ss]ubject:\s*([a-zA-Z0-9\s<>@\.,]*)$/ ? $1 : '').strip
    #logger.debug "Message from: #{from}, To: #{to}, subject: #{subject}"
    issue = Issue.new :subject => subject, :tracker_id => 3, :project_id => 1, :description => "nothing yet", \
                      :author_id => 1, :status_id => 1, :assigned_to_id => 1
    issue.save
	end

  def logger
    ::Rails.logger
  end
end