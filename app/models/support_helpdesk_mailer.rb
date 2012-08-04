class SupportHelpdeskMailer < ActionMailer::Base
  default :from => "support@yourdomain.com"
  append_view_path("#{Rails.root}/plugins/support_helpdesk/app/views")

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

end