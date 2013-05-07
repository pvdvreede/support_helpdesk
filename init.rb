# Support Helpdesk - Redmine plugin
# Copyright (C) 2012 Paul Van de Vreede
#
# This file is part of Support Helpdesk.
#
# Support Helpdesk is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Support Helpdesk is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Support Helpdesk.  If not, see <http://www.gnu.org/licenses/>.


require_dependency "support"
require_dependency "support_issue_patch"

Redmine::Plugin.register :support_helpdesk do
  name 'Support Helpdesk plugin'
  author 'Paul Van de Vreede'
  description 'Allow issues to be created from incoming emails.'
  version '2.0.0'
  url 'https://github.com/pvdvreede/support_helpdesk'
  author_url 'https://github.com/pvdvreede'

  # add menu item for settings in Admin menu
  menu :admin_menu, \
  	   :support_settings, \
  	   {:controller => :support_helpdesk_setting, :action => :index}, \
  	   :caption => "Support Helpdesk", \
       :html => { :class => "groups" }

  # add settings page for global settings
  settings :partial => 'support_global_settings', :default => {
    'support_delete_non_support_emails' => false
  }

  # ruote setup
  require 'redis'
  require 'ruote'
  require 'ruote-redis'

  RuoteKit.engine = Ruote::Engine.new(
    Ruote::Redis::Storage.new(
      Redis.new(:db => 14, :thread_safe => true)
    )
  )

  # enable to keep history of run workflows
  # RuoteKit.engine.add_service 'history', 'ruote/log/storage_history', 'Ruote::StorageHistory'

  RuoteKit.engine.context.logger.noisy = false
end

# create a generic logger
module Support
  def self.log_info(msg)
    Rails.logger.info  "support_helpdesk INFO    - #{msg}"
  end

  def self.log_warn(msg)
    Rails.logger.warn  "support_helpdesk WARNING - #{msg}"
  end

  def self.log_error(msg)
    Rails.logger.error "support_helpdesk ERROR   - #{msg}"
  end

  def self.log_debug(msg)
    Rails.logger.debug "support_helpdesk DEBUG   - #{msg}"
  end
end
