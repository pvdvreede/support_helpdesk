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

class Support::Participants::SearchCurrentIssue < Support::Participants::BaseParticipant

  def on_workitem
    workitem.fields['related_issue'] =
    if workitem.fields['email_subject'] =~ /Ticket #([0-9]+):/
      Issue.joins(:status).where(:issue_statuses => {:is_closed => false}, :id => $1).first.attributes
    elsif has_references?
      IssuesSupportMessageId.joins(:issue => :status).where(
        :message_id => searchable_ids,
        :issue_statuses => {:is_closed => false}
      ).first.issue.attributes
    end
  rescue ActiveRecord::RecordNotFound, NoMethodError => e
    Support.log_warn("Could not locate a referred issue for #{email.message_id}: #{e.message}")
  ensure
    reply
  end

  private

  def has_references?
    email.reply_to || email.references
  end

  def searchable_ids
    email.reply_to.to_a + email.references.to_a
  end

end
