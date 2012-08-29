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
	module Helper
		module Emails

      def get_email_reply_string(support, email)
        return email.from[0].to_s if not support.reply_all_for_outgoing

        #build semicolon string from all fields if not the support email
        email_array = email.to.to_a + email.from.to_a + email.cc.to_a

        email_array.find_all { |e| e.to_s.downcase unless e.to_s.downcase == support.to_email_address.downcase }.join("; ")
      end

      def send_email(issue, &block)
        begin
          mail = block.call
        rescue Exception => e
          Support.log_error "There was an error and the email was not sent because #{e}.\n#{e.backtrace}"
          notes = "There was an error and the email was not sent because #{e}"
        else
          attach_email(
            mail,
            issue,
            "Email sent from Redmine to #{mail.to[0].to_s}"
          )
        end
    end
    end
  end
end