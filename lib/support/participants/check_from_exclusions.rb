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

class Support::Participants::CheckFromExclusions < Support::Participants::BaseParticipant

  def on_workitem
    # make sure there is a from address
    if email.from.nil? || email.from.empty?
      Support.log_warn("Email #{email.message_id} had no 'from' email address.")
      cancel_workflow
      return reply
    end

    if workitem.fields['support_settings']['domains_to_ignore'].nil?
      return reply
    end

    ignore_list = workitem.fields['support_settings']['domains_to_ignore'].split(",")
    from = email.from.first.to_s
    unless ignore_list.find_all { |i| Regexp.new(i) =~ from }.empty?
      cancel_workflow
    end

    reply
  end

end
