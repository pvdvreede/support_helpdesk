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
          :address => host,
          :port => port,
          :user_name => pop_options[:username],
          :password => pop_options[:password]
        )
      end

      # get all the emails from server
      Support.log_info "Fetching emails from #{host}..."
      # emails = Mail.all

      # if emails.nil? || emails.count == 0
      #   Support.log_info "No emails to fetch."
      #   return
      # end

      handler = Support::Handler.new

      Mail.find_and_delete do |email|
        Support.log_info "Processing email #{email.message_id}..."
        status = handler.receive(email)
        if status
          # delete email from server
          Support.log_info "Processing #{email.message_id} successful and deleted from Mailbox."
        else
          # mark as not to delete and log
          Support.log_error "Processing #{email.message_id} unsuccessful message NOT deleted."
          email.skip_deletion
        end
      end

      Support.log_info "Finished fetching emails."

    end
  end
end