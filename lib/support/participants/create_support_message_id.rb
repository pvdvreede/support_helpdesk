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

class Support::Participants::CreateSupportMessageId < Support::Participants::BaseParticipant

  def on_workitem
    message_id = IssuesSupportMessageId.new(
      :issue_id                       => issue.id,
      :support_helpdesk_setting_id    => wi_support_settings['id'],
      :message_id                     => email.message_id
    )

    # TODO This only links to the parent, it needs to link to the related issue
    # which might not necessarily be the parent.
    unless issue.issues_support_message_ids.empty?
      message_id.parent = issue.issues_support_message_ids.find do |id|
        id.parent == nil
      end
    end

    message_id.save!

    reply
  end

  private

  def issue
    @issue ||= Issue.find(wi_related_issue['id'].to_i)
  end

end
