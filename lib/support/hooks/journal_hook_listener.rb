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
        return unless context[:issue].respond_to?(:support_helpdesk_setting)

        # only show email user if available on the issue
        return if context[:issue].reply_email.nil? or context[:issue].reply_email == ''

        # get a list of emails and people to send to
        emails = Array.new
        # put blank option in
        emails << ["Select a person to email to...", ""]
        # get all emails on issue
        reply_emails = context[:issue].reply_email.split "; "
        # add special option if there is more than one reply email
        if reply_emails.count > 1
          emails << ["Email all involved", context[:issue].reply_email]
        end
        emails = emails + reply_emails.map { |r| [r.downcase, r.downcase] }
        

        # add all users of Redmine
        emails = emails + User.where("mail != ?", "").map { |u| [u.name, u.mail.downcase] }

        context[:controller].send(:render_to_string, {
          :partial => "issues/email_to_user_option",
          :locals => { :context => context, :emails => emails }
        })

      end

      def controller_issues_edit_before_save(context={})
        issue = context[:issue]

        # code for sending email to user
        if context[:params][:email_to_user] && context[:params][:email_to_user_address]
          # double check that we can email the user
          return unless issue.can_send_item?

          notes = context[:journal].notes
          return if notes == ""

          send_email(issue) do
            mail = SupportHelpdeskMailer.user_question(
              issue,
              textilizable(notes),
              context[:params][:email_to_user_address]
            ).deliver
          end
        end

        if context[:params][:resend_creation_email] && context[:params][:resend_creation_email_address]
          return unless issue.can_send_item?

          send_email(issue) do
            mail = SupportHelpdeskMailer.ticket_created(
              issue, 
              context[:params][:resend_creation_email_address]
            ).deliver
          end
        end

        if context[:params][:resend_closing_email] && context[:params][:resend_closing_email_address]
          return unless issue.can_send_item?

          send_email(issue) do
            mail = SupportHelpdeskMailer.ticket_closed(
              issue, 
              context[:params][:resend_closing_email_address]
            ).deliver
          end
        end
      end
      
    end
  end
end