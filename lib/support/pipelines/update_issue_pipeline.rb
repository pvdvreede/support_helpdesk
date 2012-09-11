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
      include Support::Helper::Misc

      def should_run?
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
        end

        # check and see if we have logged messages in the References or In-Reply-To
        unless email.reply_to.nil?
          email_reply = IssuesSupportMessageId.find_by_message_id(email.reply_to)
          return false if email_reply.nil?
          issue = email_reply.issue
        end
        unless email.references.nil?
          email_reference = IssuesSupportMessageId.find_by_message_id(email.references)
          return false if email_reference.nil?
          issue = email_reference.issue
        end
        
        # if we have an issue in the context we need to make sure its not closed
        # before deciding to run or not.
        unless issue.nil?
          unless issue.status.is_closed
            @context[:issue] = issue
            return true
          end
        end

        false
      end

      def execute
        # get the email and issue to work with
        email = @context[:email]
        issue = @context[:issue]

        attach_email(
          email, 
          issue, 
          "Email received from #{email.from[0].to_s}.",
          @context[:body]
        )
        
        # TODO update the issue updated time
        

        # update the last processed time
        update_last_processed(issue.support_helpdesk_setting)

        raise Support::PipelineProcessingSuccessful.new "Issue #{issue.id} updated with email from #{email.from[0].to_s}."
      end
    end
  end
end