class SupportHelpdeskMailer < ActionMailer::Base
  default :parts_order => ["text/html", "text/plain"]

  # TODO make this less dependent on plugin folder name
  append_view_path("#{Rails.root}/plugins/support_helpdesk/app/views")

  def ticket_created(issue, to)
    @issue = issue
    @support = issue.support_helpdesk_setting
    Support.log_info "Sending ticket creation support email..."
    mail(:to => to, 
         :from => @support.from_email_address,
         :subject => "#{@support.name} Ticket ##{@issue.id} created: #{issue.subject}", 
         :template_name => @support.created_template_name
         )
  end

  def ticket_closed(issue, to)
    @issue = issue
    @support = issue.support_helpdesk_setting
    Support.log_info "Sending closing support email..."
    mail(:to => to,
         :from => @support.from_email_address,
         :subject => "#{@support.name} Ticket ##{@issue.id} closed: #{issue.subject}", 
         :template_name => @support.closed_template_name
         )
  end

  def user_question(issue, question, to)
    @issue = issue
    @support = issue.support_helpdesk_setting
    @question = question
    mail(:to => to, 
         :from => @support.from_email_address,
         :subject => "#{@support.name} Ticket ##{@issue.id} update: #{issue.subject}", 
         :template_name => @support.question_template_name
         )
  end
end