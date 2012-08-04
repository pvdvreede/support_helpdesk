class JournalEditHookListener < Redmine::Hook::ViewListener
  def controller_issues_edit_before_save(context={})
    if context[:params][:email_to_user]
      notes = context[:journal].notes
      SupportHelpdeskSetting.where(:tracker_id)
      cus = context[:issue].custom_field_values.select {|x| x.custom_field_id == field_id }
      ::Rails.logger.debug "Will send the note #{notes} to the user."
      # TODO alter flash object to inform user the email has been sent
      #context[:controller].send("flash[:notice]=", "Email sent to user.")
    end
  end
end