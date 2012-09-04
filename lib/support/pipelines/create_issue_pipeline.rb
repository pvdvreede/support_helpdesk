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
    class CreateIssuePipeline < Support::Pipeline::PipelineBase
      include Support::Helper::Attachments
      include Support::Helper::Emails
      include Support::Helper::Misc

      def execute
        support = @context[:support]
        project = @context[:project]
        email = @context[:email]

        issue = Issue.new(
          :subject => email.subject.to_s,
          :tracker_id => support.tracker_id,
          :project_id => project.id,
          :description => @context[:body],
          :author_id => support.author_id,
          :status_id => support.new_status_id,
          :assigned_to_id => support.assignee_group_id,
          :start_date => Time.now.utc
        )
        issue.support_helpdesk_setting = support
        issue.reply_email = get_email_reply_string(support, email)
        issue.support_type = support.name

        begin
          unless issue.save
            Support.log_error "Error saving issue because #{issue.errors.full_messages.join("\n")}"
            raise Support::PipelineProcessingError.new "Error saving issue: #{issue.errors.full_messages.join("\n")}"
          end
        rescue Support::PipelineProcessingError => e
          raise e
        rescue => e
          Support.log_error "Exception occured while saving issue: #{e}"
          Suuport.log_debug "Exception backtrace:\n#{e.backtrace}"
          raise Support::PipelineProcessingError.new "Exception while saving issue: #{e}"
        end

        attach_email(
          email,
          issue,
          "Original email from client."
        )

        # send email back to ticket creator if it has been requested
        if support.send_created_email_to_user
          send_email(issue) do
            SupportHelpdeskMailer.ticket_created(issue, issue.reply_email).deliver
          end
        end

        # update the last processed time
        update_last_processed(@context[:support])

        @context
      end
  	end
  end
end
