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
      def should_run?(context)
        # see if this is an update to an existing ticket based on subject
        email = @context[:email]
        subject = email.subject.to_s
        id = (subject =~ /Ticket #([0-9]*)/ ? $1 : false)
        unless id == false
          @context[:issue_id] = id
          return true
        end

        # check and see if we have logged messages in the References or In-Reply-To
        unless email.reply_to.nil?
          email_reply = IssuesSupportMessageId.where(:message_id => email.reply_to)[0]
          return email_reply.issue_id unless email_reply.nil?
        end
        unless email.references.nil?
          email_reference = IssuesSupportMessageId.where(:message_id => email.references)[0]
          return email_reference.issue_id unless email_reference.nil?
        end

        false
      end
    end
  end
end