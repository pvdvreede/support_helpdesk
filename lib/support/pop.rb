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

module Support
	module POP
	  def self.check(pop_options={})
	    host = pop_options[:host] || '127.0.0.1'
      port = pop_options[:port] || '110'

      Mail.defaults do
        retriever_method(
          :pop3,
          :address      => host,
          :port         => port,
          :user_name    => pop_options[:username],
          :password     => pop_options[:password]
        )
      end

      # get all the emails from server
      Support.log_info "Fetching emails from #{host}:#{port} with POP3..."
      handler = Support::Workflow.new(RuoteKit.engine)
      Mail.find_and_delete do |email|
        begin
          Support.log_info "Processing email #{email.message_id} from #{email.from.first} with subject #{email.subject || "No subject"}..."

          wfid = handler.receive_email(email)

          unless wfid == email.message_id
            raise "WFID does not match the email message id"
          end
        rescue => e
          email.skip_deletion
          Support.log_error "There was an error trying to push #{email.message_id} into Ruote: #{e.message}. #{e.backtrace.join(", ")}"
        end
      end

      Support.log_info "Finished fetching emails."
      SupportHelpdeskSetting.update_all(
        { :last_run   => Time.now },
        { :active     => true }
      )
    end
  end
end
