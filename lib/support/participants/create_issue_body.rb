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
      reply_stripped_body(email.text_part.body.decoded)
    elsif email.content_type.include? "text/html"
      raise TypeError.new("Email only contains html.")
    else
      reply_stripped_body(email.body.decoded)
    end
  rescue => e
    Support.log_warn "Could not decode email body of #{email.message_id}: #{e.message}."
    workitem.fields['email_body'] = "Cannot add body, please open attached email file."
  ensure
    reply
  end

  private

  def reply_stripped_body(body)
    notes = body

    stripping_rules.find do |r|
      Support.log_debug "Running rule #{r.to_s}."
      reply_match = body.match(r)
      unless reply_match.nil?
        Support.log_debug "Match found at #{reply_match.begin(0)}."
        notes = body[0, reply_match.begin(0)]
        Support.log_debug "Email reply body is now set to:\n#{notes}"
        next true
      end
    end

    notes
  end

  def stripping_rules
    [
      /^.*\s+<.*>\s*wrote:.*$/,
      /^_+\nFrom:\s*.*\s*(<|\[).*(>|\])$/,
      /^Date:.+\nSubject:.+\nFrom: .*$/,
      /^----- Original Message -----$/,
      /^\s*_+\s*\nFrom: .* (<|\[).*(>|\])$/,
      /\nFrom:\s*.*\s*(<|\[).*(>|\])/
    ]
  end

end
