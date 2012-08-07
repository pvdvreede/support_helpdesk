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
  default :parts_order => ["text/html", "text/plain"]

  # add current plugins views folder as a place to look for views
  append_view_path("#{File.expand_path(File.dirname(__FILE__))}/../views")

  # make sure we throw errors regardless of the users setting so we can catch them
  self.raise_delivery_errors = true

  def ticket_created(issue, to)
    @issue = issue
    @support = issue.support_helpdesk_setting
    Support.log_info "Sending ticket creation support email..."
    mail(:to => to, 
         :from => @support.from_email_address,
         :subject => "#{@support.name} Ticket ##{@issue.id} created: #{issue.subject}", 
         :template_name => @support.created_template_name
         )
  end

  def ticket_closed(issue, to)
    @issue = issue
    @support = issue.support_helpdesk_setting
    Support.log_info "Sending closing support email..."
    mail(:to => to,
         :from => @support.from_email_address,
         :subject => "#{@support.name} Ticket ##{@issue.id} closed: #{issue.subject}", 
         :template_name => @support.closed_template_name
         )
  end

  def user_question(issue, question, to)
    @issue = issue
    @support = issue.support_helpdesk_setting
    @question = question
    mail(:to => to, 
         :from => @support.from_email_address,
         :subject => "#{@support.name} Ticket ##{@issue.id} update: #{issue.subject}", 
         :template_name => @support.question_template_name
         )
  end
end