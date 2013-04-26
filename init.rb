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
require_dependency "pop3"
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
  require 'ruote'
  require 'ruote-sequel'

  db = HashWithIndifferentAccess.new
  db.merge!(ActiveRecord::Base.configurations[Rails.env])
  if db[:adapter] == 'sqlite3'
    RUOTE_STORAGE = Sequel.connect("sqlite://#{db[:database]}")
  else
    db.merge!(:user => db[:user_name] || "")
    RUOTE_STORAGE = Sequel.connect(db)
  end

  opts = { 'sequel_table_name' => 'support_ruote_docs' }

  Ruote::Sequel.create_table(RUOTE_STORAGE, false, opts['sequel_table_name'])

  RuoteKit.engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::Sequel::Storage.new(RUOTE_STORAGE, opts)))

  unless $RAKE_TASK # don't register participants in rake tasks
    RuoteKit.engine.register do
      # register your own participants using the participant method
      #
      # Example: participant 'alice', Ruote::StorageParticipant see
      # http://ruote.rubyforge.org/participants.html for more info

      # register the catchall storage participant named '.+'

      catchall
    end
  end

  RuoteKit.engine.context.logger.noisy = false
end

# create a generic logger
module Support
  def self.log_info(msg)
    Rails.logger.info "#{Time.now.to_s} support_helpdesk INFO    - #{msg}"
  end

  def self.log_warn(msg)
    Rails.logger.warn "#{Time.now.to_s} support_helpdesk WARNING - #{msg}"
  end

  def self.log_error(msg)
    Rails.logger.error "#{Time.now.to_s} support_helpdesk ERROR  - #{msg}"
  end

  def self.log_debug(msg)
    Rails.logger.debug "#{Time.now.to_s} support_helpdesk DEBUG  - #{msg}"
  end
end
