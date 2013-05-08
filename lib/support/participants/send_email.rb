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

class Support::Participants::SendEmail < Support::Participants::BaseParticipant

  def on_workitem
    issue = Issue.find(wi_related_issue['id'].to_i)

    mail = ::SupportHelpdeskMailer.__send__(template, issue, to, opts)
    mail.deliver

    self.wi_outgoing_email = mail.to_yaml

    reply
  end

  private

  def template
    workitem.params['template'].to_sym
  end

  def to
    workitem.param_or_field('outgoing_email_to')
  end

  def opts
    if workitem.fields.has_key?('outgoing_email_opts')
      workitem.fields['outgoing_email_opts']
    else
      {}
    end
  end

end
