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

class Support::Participants::CreateSupportIssue < Support::Participants::BaseParticipant

  def on_workitem
    issue = Issue.new(
      :subject                   => wi_email_subject,
      :description               => wi_email_body,
      :support_helpdesk_setting  => SupportHelpdeskSetting.find(wi_support_settings['id']),
      :project_id                => wi_related_project['id'],
      :priority_id               => wi_support_settings['priority_id'],
      :tracker_id                => wi_support_settings['tracker_id'],
      :author_id                 => wi_support_settings['author_id'],
      :status_id                 => wi_support_settings['new_status_id'],
      :assigned_to_id            => wi_support_settings['assignee_group_id']
    )
    issue.custom_field_values = {
      wi_support_settings['reply_email_custom_field_id'] => wi_email_reply_to,
      wi_support_settings['type_custom_field_id']        => wi_support_settings['name']
    }
    issue.save!
    issue.save_custom_field_values
    self.wi_related_issue = issue.attributes
    self.wi_issue_created = true
    reply
  end

end
