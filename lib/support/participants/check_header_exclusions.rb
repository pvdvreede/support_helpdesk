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

class Support::Participants::CheckHeaderExclusions < Support::Participants::BaseParticipant

  def on_workitem
    cancel_workflow if has_suppression_headers?

    reply
  end

  private

  def has_suppression_headers?
    return false if email.header['X-Auto-Response-Suppress'].nil?

    !(["OOF", "AutoReply"] & suppressions).empty?
  end

  def suppressions
    email.header['X-Auto-Response-Suppress'].to_s.split(",").map(&:strip)
  end

end
