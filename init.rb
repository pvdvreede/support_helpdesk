require_dependency "pop3"
require_dependency "email"
require_dependency "issue_patch"
require_dependency "journal_hook_listener"
require_dependency "journal_edit_hook_listener"

Redmine::Plugin.register :support_helpdesk do
  name 'Support Helpdesk plugin'
  author 'Paul Van de Vreede'
  description 'Allow issues to be created from incoming emails.'
  version '0.5.0'
  url 'http://github.com/pvdvreede/support_helpdesk'
  author_url 'http://github.com/pvdvreede'
end
