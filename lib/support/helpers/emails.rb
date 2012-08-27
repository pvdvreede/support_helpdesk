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
      def get_email_body_text(email)
        begin
          html_encode = false

          # handle single part emails
          unless email.multipart?
            part = email

            if email.content_type.include? "text/html"
              raise TypeError.new "Email is html only."
            end
          else
            if email.text_part.nil? == false
              part = email.text_part
            elsif email.html_emailpart.nil? == false
              raise TypeError.new "Email only has html part."
              #part = email.html_part
              #html_encode = true
            else
              raise TypeError.new "Email does not have text or html part."
            end
          end

          body = part.body.decoded

          # split and only give the first 40 lines
          body_array = body.split("\n")
          if body_array.count <= 30
            return body
          end
          # other get the first 30 lines and return those.
          new_body = body_array[0..29].join "\n"
          # add on notice it is not the end of the email
          return new_body + "\n\n=====================================\nEmail has been truncated at 30 lines, please open attached email to check the rest..."
        rescue => ex
          Support.log_error "Exception trying to load email body so using static text: #{ex}"
          body = "Could not decode email body. Email body in attached email."
        end
        body
      end

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