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

require 'erb'

class Support::Participants::UpdateSupportIssue < Support::Participants::BaseParticipant

  def on_workitem
    journal = Journal.new(
      :notes        => notes,
      :user_id      => user_id,
    )

    issue.journals << journal
    issue.updated_on = Time.now
    issue.save!

    # add the journal to the context
    self.wi_related_journal = journal.attributes
    self.wi_issue_created   = false

    reply
  end

  private

  def issue
    @issue ||= Issue.find(wi_related_issue['id'].to_i)
  end

  def notes
    ERB.new(notes_template).result(binding)
  end

  def user_id
    wi_support_settings['author_id']
  end

  def notes_template
<<-NOTES
Email received from <%= email.from.first %> at <%= Time.now %> and is attached:

<%= wi_email_body %>

NOTES
  end

end
