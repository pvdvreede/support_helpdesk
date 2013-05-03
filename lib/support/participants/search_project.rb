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

class Support::Participants::SearchProject < Support::Participants::BaseParticipant

  def on_workitem
    # check if project custom field values matches email from domain
    value_field = CustomValue.where(
      :customized_type => 'Project',
      :custom_field_id => wi_support_settings['email_domain_custom_field_id'],
      :value => email_domain
    ).first
    # if there isnt one use the support default project
    self.wi_related_project =
    if value_field.nil?
      Project.find(wi_support_settings['project_id'].to_i).attributes
    else
      Project.find(value_field.customized_id).attributes
    end

    reply
  end

  private

  def email_domain
    email.from.first.downcase.split("@")[1]
  end

end
