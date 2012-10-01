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
    class AddEmailAttachmentPipeline < Support::Pipeline::PipelineBase
      include Support::Helper::Attachments

      def execute
        # get the email we are adding
        email = @context[:email]
        body = @context[:body]

        # get the issue we are adding it to
        issue = @context[:issue]

        # create the journal entry to put the body
        attach_email(email, issue, "Email received from #{email.from.first.to_s}.", body)

        if @context.has_key?(:sent_mail)
          sent_mail = @context[:sent_mail]
          attach_email(sent_mail, issue, "Generated email sent.")
        end
        @context
      end

    end
  end
end