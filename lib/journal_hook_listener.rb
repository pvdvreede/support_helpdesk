class JournalHookListener < Redmine::Hook::ViewListener
  #render_on :view_issues_edit_notes_bottom, :partial => "issues/email_to_user_option"

  def view_issues_edit_notes_bottom(context={})
    tracker_id = context[:issue].tracker_id
    support_setting = SupportHelpdeskSetting.where(:tracker_id => tracker_id)
    if is_support_issue? context[:issue]
      context[:controller].send(:render_to_string, {
        :partial => "issues/email_to_user_option",
        :locals => context
      })
    end
  end

  private
  def is_support_issue?(issue)
    # get all custom field ids for replies from all support types
    field_ids = SupportHelpdeskSetting.select(:reply_email_custom_field_id)
    # check if the issue has a reply email address custom field
    reply_address = CustomValue.where(:customized_id => issue.id, :custom_field_id => field_ids)
    if reply_address.count > 0
      return true
    end
  end 
end
    