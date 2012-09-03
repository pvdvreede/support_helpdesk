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
  module Hooks
    class JournalHookListener < Redmine::Hook::ViewListener
      include Support::Helper::Emails
      include Support::Helper::Attachments

      def view_issues_edit_notes_bottom(context={})
        # only show email to user if there is a support setup
        begin
          support = context[:issue].support_helpdesk_setting
          return if support == nil
        rescue NoMethodError => e
          Support.log_error "Support method not present on issue!"
          return
        end

        # only show email user if available on the issue
        if context[:issue].reply_email != nil and context[:issue].reply_email != ''
          context[:controller].send(:render_to_string, {
            :partial => "issues/email_to_user_option",
            :locals => context
          })
        end
      end

      def controller_issues_edit_before_save(context={})
        issue = context[:issue]

        # code for sending email to user
        if context[:params][:email_to_user]
          # double check that we can email the user
          return unless issue.can_send_item?

          notes = context[:journal].notes
          return if notes == ""

          send_email(issue) do
            mail = SupportHelpdeskMailer.user_question(
              issue,
              textilizable(notes),
              issue.reply_email
            ).deliver
          end
        end

        if context[:params][:resend_creation_email]
          return unless issue.can_send_item?

          send_email(issue) do
            mail = SupportHelpdeskMailer.ticket_created(issue, issue.reply_email).deliver
          end
        end

        if context[:params][:resend_closing_email]
          return unless issue.can_send_item?

          send_email(issue) do
            mail = SupportHelpdeskMailer.ticket_closed(issue, issue.reply_email).deliver
          end
        end
      end
      
    end
  end
end