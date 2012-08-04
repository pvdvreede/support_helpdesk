class JournalHookListener < Redmine::Hook::ViewListener

  def view_issues_edit_notes_bottom(context={})
    # only show email user if available on the issue
    if context[:issue].reply_email != nil
      context[:controller].send(:render_to_string, {
        :partial => "issues/email_to_user_option",
        :locals => context
      })
    end
  end

  def controller_issues_edit_before_save(context={})
    if context[:params][:email_to_user]
      # double check that we can email the user
      issue = context[:issue]
      reply_email = issue.reply_email
      return if reply_email == nil or reply_email == ""

      notes = context[:journal].notes

      ::Rails.logger.info "Emailing note for #{issue.id} to #{reply_email}."
      mail = SupportHelpdeskMailer.user_question(issue, notes, reply_email)
      mail.deliver

      # add info to the note so we know it was emailed.
      context[:journal].notes = <<-NOTE
Emailed to #{reply_email} at #{Time.now.to_s}: 

#{notes}
NOTE

      # TODO save the email sent for our records
    end
  end

end
    