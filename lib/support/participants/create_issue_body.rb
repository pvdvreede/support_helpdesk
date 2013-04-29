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

class Support::Participants::CreateIssueBody < Support::Participants::BaseParticipant

  def on_workitem
    workitem.fields['email_body'] =
    if email.multipart? && !email.text_part.nil?
      email.text_part.body.decoded
    elsif email.content_type.include? "text/html"
      raise TypeError.new("Email only contains html.")
    else
      email.body.decoded
    end
  rescue => e
    Support.log_warn "Could not decode email body of #{email.message_id}: #{e.message}."
    workitem.fields['email_body'] = "Cannot add body, please open attached email file."
  ensure
    reply
  end

end
