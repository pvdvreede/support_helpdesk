require_dependency "pop3"
require_dependency "issue_patch"
require_dependency "journal_hook_listener"

Redmine::Plugin.register :support_helpdesk do
  name 'Support Helpdesk plugin'
  author 'Paul Van de Vreede'
  description 'Allow issues to be created from incoming emails.'
  version '0.5.0'
  url 'http://github.com/pvdvreede/support_helpdesk'
  author_url 'http://github.com/pvdvreede'

  # add menu item for settings in Admin menu
  menu :admin_menu, \
  	   :support_settings, \
  	   {:controller => :support_helpdesk_setting, :action => :index}, \
  	   :caption => "Support Helpdesk", \
       :html => { :class => "groups" }
end

# create a generic logger
module Support
  def self.log_info(msg)
    Rails.logger.info "support_helpdesk - #{msg}"
  end

  def self.log_error(msg)
    Rails.logger.error "support_helpdesk - #{msg}"
  end
end
