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

class SupportHelpdeskMailer < ActionMailer::Base
  # include time format helper
  add_template_helper(Redmine::I18n)
  add_template_helper(ApplicationHelper)

  default :parts_order => ["text/html", "text/plain"]

  # make sure we throw errors regardless of the users setting so we can catch them
  self.raise_delivery_errors = true

  def ticket_created(issue, to, opts={})
    @issue = issue
    @support = issue.support_helpdesk_setting
    add_email_headers
    prepend_view_path(Setting.plugin_support_helpdesk['support_template_path'])
    Support.log_info "Sending ticket creation support email from #{@support.from_email_address}..."
    mail(
      :to               => create_to_from_string(to),
      :from             => @support.from_email_address,
      :bcc              => @support.bcc_email || nil,
      :subject          => subject,
      :template_name    => @support.created_template_name,
      :template_path    => '.'
    )
  end

  def ticket_closed(issue, to, opts={})
    @issue = issue
    @support = issue.support_helpdesk_setting
    add_email_headers
    prepend_view_path(Setting.plugin_support_helpdesk['support_template_path'])
    Support.log_info "Sending closing support email from #{@support.from_email_address}..."
    mail(
      :to               => create_to_from_string(to),
      :from             => @support.from_email_address,
      :bcc              => @support.bcc_email || nil,
      :subject          => subject,
      :template_name    => @support.closed_template_name,
      :template_path    => '.'
    )
  end

  def user_question(issue, to, opts={})
    @issue    = issue
    @support  = issue.support_helpdesk_setting
    @question = opts[:question]
    add_email_headers
    prepend_view_path(Setting.plugin_support_helpdesk['support_template_path'])
    Support.log_info "Sending user question email from #{@support.from_email_address}..."
    mail(
      :to               => create_to_from_string(to),
      :from             => @support.from_email_address,
      :bcc              => @support.bcc_email || nil,
      :subject          => subject,
      :template_name    => @support.question_template_name,
      :template_path    => '.'
    )
  end

  private

  def subject
    "#{@support.name} Ticket ##{@issue.id.to_s}: #{@issue.subject}"
  end

  def add_email_headers
    headers["X-SupportTicket-Id"] = @issue.id.to_s
    headers["X-Auto-Response-Suppress"] = "OOF, DR, AutoReply"
    unless @issue.issues_support_message_ids.empty?
      related_message = @issue.issues_support_message_ids.root
      headers["References"] = "<#{related_message.message_id}>"

      # get the descendants to reply to the last email, if there are any
      descendants = related_message.descendants
      if descendants.nil? || descendants.count == 0
        headers["In-Reply-To"] = "<#{related_message.message_id}>"
      else
        headers["In-Reply-To"] = "<#{descendants.last.message_id}>"
      end
    end
  end

  def create_to_from_string(email_string)
    email_string.split(";").map { |e| e.strip }
  end
end
