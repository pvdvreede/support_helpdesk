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

class Support::Participants::AddEmailAttachment < Support::Participants::BaseParticipant

  def on_workitem
    attachment = Attachment.create!(
      :filename         => email_filename,
      :content_type     => "message/rfc822",
      :author_id        => user_id,
      :container        => issue,
      :file             => email.encoded,
      :description      => description
    )

    journal_detail = JournalDetail.create!(
      :journal_id       => journal.id,
      :property         => 'attachment',
      :prop_key         => attachment.id,
      :value            => email_filename
    )

    self.wi_related_attachment = attachment.attributes

    reply
  end

  private

  def issue
    @issue ||= Issue.find(wi_related_issue['id'].to_i)
  end

  def email_filename
    "#{email.from.first.downcase}_#{Time.now.strftime("%Y%m%d%H%M%S")}.eml"
  end

  def description
    if wi_issue_created
      "Original email sent from Customer."
    else
      "Supplemental email received from #{email.from.first.downcase}."
    end
  end

  def user_id
    wi_support_settings['author_id']
  end

  def journal
    if wi_issue_created && wi_related_journal.nil?
      journal = Journal.create!(
        :user_id      => user_id,
        :journalized  => issue
      )

      self.wi_related_journal = journal.attributes
      @journal = journal
    end

    @journal ||= Journal.find(wi_related_journal['id'].to_i)
  end


end
