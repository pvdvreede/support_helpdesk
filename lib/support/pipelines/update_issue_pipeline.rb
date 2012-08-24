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
    class UpdateIssuePipeline < Support::Pipeline::PipelineBase
      include Support::Helper::Attachments

      def should_run?(context)
        # see if this is an update to an existing ticket based on subject
        email = @context[:email]
        subject = email.subject.to_s
        id = (subject =~ /Ticket #([0-9]*)/ ? $1 : false)
        unless id == false
          begin
            issue = Issue.find id
          rescue ActiveRecord::RecordNotFound
            return false
          end
          @context[:issue] = issue
          return true
        end

        # check and see if we have logged messages in the References or In-Reply-To
        unless email.reply_to.nil?
          email_reply = IssuesSupportMessageId.find_by_message_id(email.reply_to)
          return false if email_reply.nil?
          @context[:issue] = email_reply.issue
          return true
        end
        unless email.references.nil?
          email_reference = IssuesSupportMessageId.find_by_message_id(email.references)
          return false if email_reference.nil?
          @context[:issue] = email_reference.issue
          return true
        end

        false
      end

      def execute
        # get the email and issue to work with
        email = @context[:email]
        issue = @context[:issue]

        attach_email(email, issue, "Email received from #{email.from[0].to_s}.")

        raise Support::PipelineProcessingSuccessful.new "Issue #{issue.id} updated with email from #{email.from[0].to_s}."
      end
    end
  end
end