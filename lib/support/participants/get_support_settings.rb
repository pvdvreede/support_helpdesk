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

class Support::Participants::GetSupportSettings < Support::Participants::BaseParticipant

  def on_workitem
    to_emails = (email.to.to_a + email.cc.to_a).map { |e| e.downcase }

    setting = SupportHelpdeskSetting.active.where(:to_email_address => to_emails).first

    if setting && applies?(setting)
      workitem.fields['support_settings'] = setting.attributes
    else
      cancel_workflow
    end

    reply
  end

  private

  def applies?(setting)
    return true if setting.search_in_to && setting.search_in_cc

    if setting.search_in_to
      email.to.to_a.include?(setting.to_email_address)
    else
      email.cc.to_a.include?(setting.to_email_address)
    end
  end

end
