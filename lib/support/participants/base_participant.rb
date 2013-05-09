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

class Support::Participants::BaseParticipant < Ruote::Participant

  def on_cancel
    Support.log_warn "on_cancel method called for #{participant_name} participant."
  end

  protected

  def email
    @email ||= Mail::Message.from_yaml(wi_email)
  end

  def cancel_workflow
    Support.log_info("Email #{email.message_id} workflow is being cancelled from #{participant_name} participant.")
    self.wi_cancel = true
  end

  def method_missing(name, *args, &block)
    Support.log_debug "method_missing called on #{participant_name} participant with values: #{name.to_s}, #{args.inspect}."
    if name.to_s =~ /^wi_([a-z0-9_]+)$/
      workitem.fields[$1]
    elsif name.to_s =~ /^wi_([a-z0-9_]+)=$/
      workitem.fields[$1] = args[0]
    else
      super
    end
  end

end
