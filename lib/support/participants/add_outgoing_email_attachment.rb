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

class Support::Participants::AddOutgoingEmailAttachment < Support::Participants::AddEmailAttachment

  protected

  def attach_to_work_item
    self.wi_outgoing_email_attachment = @attachment.attributes
  end

  def email_file
    outgoing_email.encoded
  end

  def outgoing_email
    @outgoing_email ||= Mail::Message.from_yaml(wi_outgoing_email)
  end

  def email_filename
    "#{outgoing_email.from.first.downcase}_#{Time.now.strftime("%Y%m%d%H%M%S")}_#{filename_hash[0..5]}.eml"
  end

  def filename_hash
    Digest::SHA1.hexdigest(outgoing_email.message_id)
  end

  def description
    "Email sent by us to #{outgoing_email.to.join(", ")}."
  end

  def journal
    @journal ||= Journal.create!(
      :user_id      => user_id,
      :journalized  => issue,
      :notes        => description
    )
  end

end
