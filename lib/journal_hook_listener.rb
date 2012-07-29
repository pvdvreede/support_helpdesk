class JournalHookListener < Redmine::Hook::ViewListener
  render_on :view_issues_edit_notes_bottom, :partial => "issues/email_to_user_option"
end
    