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


# Majority of code in this file is taken from Redmine::POP3 module
require 'net/pop'

module Support
	module POP3
    class << self
  		def check(handler, pop_options={})
  			host = pop_options[:host] || '127.0.0.1'
        port = pop_options[:port] || '110'
        apop = (pop_options[:apop].to_s == '1')
        pop = Net::POP3.APOP(apop).new(host, port)
        Support.log_info "Connecting to #{host}:#{port}..."
        pop.start(pop_options[:username], pop_options[:password]) do |pop_session|
          if pop_session.mails.empty?
            Support.log_info "No emails to fetch."
          else
            pop_session.each_mail do |mail|
              message = mail.pop
              message_id = (message =~ /^Message-I[dD]: (.*)/ ? $1 : '').strip
              Support.log_info "Processing message with message id #{message_id}..."
              # convert message into rails mail object
              mail_obj = Mail.new message
              if handler.receive(mail_obj)
                mail.delete
                Support.log_info "Message #{message_id} processed and deleted from the mailbox."
              end
            end
          end

          # add time of last run to all active support settings
          SupportHelpdeskSetting.update_all(
            {:last_run => Time.now.utc},
            {:active => true}
            )
        end
      end
    end
  end
end