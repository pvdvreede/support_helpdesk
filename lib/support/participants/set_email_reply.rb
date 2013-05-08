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

class Support::Participants::SetEmailReply < Support::Participants::BaseParticipant

  def on_workitem
    self.wi_email_reply_to = reply_list

    reply
  end

  private

  def reply_list
    list = (email.from.to_a + email.to.to_a).map { |e| e.downcase }.reject do |e|
      e == wi_support_settings['to_email_address'].downcase
    end
    list.join "; "
  end

end
