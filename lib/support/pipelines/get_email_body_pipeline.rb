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
  module Pipeline
    class GetEmailBodyPipeline < Support::Pipeline::PipelineBase
      def execute
      	# get the email to work with
      	email = @context[:email]

        begin
          text_body = get_email_body_text(email)
          reply_body = get_reply_only(text_body, email.message_id)
        rescue => e
          Support.log_error "There was an error stripping the reply out of the email body: #{e}"
          Support.log_debug "Error backtrace:\n#{e.backtrace}"
          reply_body = "Could not decode email body. Email body in attached email."
        end

        @context[:body] = reply_body
        @context
      end

      private
      def get_email_body_text(email)

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
          else
            raise TypeError.new "Email does not have text or html part."
          end
        end

        part.body.decoded
      end

      def get_reply_only(body, message_id)

        rules = [
          /^.*\s+<.*>\s*wrote:.*$/,
          /^_+\nFrom:\s*.*\s*(<|\[).*(>|\])$/,
          /^Date:.+\nSubject:.+\nFrom: .*$/,
          /^----- Original Message -----$/,
          /^\s*_+\s*\nFrom: .* (<|\[).*(>|\])$/,
          /\nFrom:\s*.*\s*(<|\[).*(>|\])/

          # TODO: other email clients/services

        ]

        # Default to using the whole body as the reply (maybe the user deleted the original message when they replied?)
        notes = body

        rules.find do |r|
          Support.log_debug "Running rule #{r.to_s}."
          reply_match = body.match(r)
          unless reply_match.nil?
            Support.log_debug "Match found at #{reply_match.begin(0)}."
            notes = body[0, reply_match.begin(0)]
            Support.log_debug "Email reply body is now set to:\n#{notes}"
            next true
          end
        end

        notes
      end
  	end
  end
end
