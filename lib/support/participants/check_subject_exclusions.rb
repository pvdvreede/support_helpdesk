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

class Support::Participants::CheckSubjectExclusions < Support::Participants::BaseParticipant

  def on_workitem
    # make sure there is a subject or set one
    if email.subject.nil? || email.subject.empty?
      Support.log_warn("Email #{email.message_id} had no 'subject' so I'm giving it one.")
      workitem.fields['email_subject'] = "(no subject)"
      return reply
    end

    subject = email.subject.to_s

    if workitem.fields['support_settings']['subject_exclusion_list'].nil?
      workitem.fields['email_subject'] = subject
      return reply
    end

    ignore_list = workitem.fields['support_settings']['subject_exclusion_list'].split(",")
    unless ignore_list.find_all { |i| Regexp.new(i) =~ subject }.empty?
      cancel_workflow
    else
      workitem.fields['email_subject'] = subject
    end

    reply
  end

end
