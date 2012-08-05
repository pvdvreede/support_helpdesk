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
      return if notes == ""

      Support.log_info "Emailing note for #{issue.id} to #{reply_email}."
      begin
        mail = SupportHelpdeskMailer.user_question(issue, notes, reply_email).deliver
      rescue Exception => e
        Support.log_error "Error in sending email for #{issue.id}: #{e}\n#{e.backtrace.join("\n")}"
        email_status = "Error sending email, email was *NOT* sent:"
      else
        email_status = "Emailed to #{reply_email} at #{Time.now.to_s}:"

        # save the email sent for our records
        SupportMailHandler.attach_email(
            issue,
            mail.encoded,
            "#{mail.from}_#{mail.to}.msg",
            "Email sent to user from note."
          )
      end

      # add info to the note so we know it was emailed.
      context[:journal].notes = <<-NOTE
#{email_status} 

#{notes}
NOTE

    end
  end

end
    