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

module Support
  module Pipeline
    class SupportPipeline < Support::Pipeline::PipelineBase
      def execute
        # get the email
        email = @context[:email]

        # join all possible emails address into one array for looping
        emails = email.to.to_a + email.cc.to_a + email.bcc.to_a
        where_string = ""
        where_array = []
        emails.each do |e|
          where_string += "LOWER(to_email_address) LIKE ?"
          where_string += " OR " unless emails.last == e
          where_array.push "%#{e.to_s.downcase}%"
        end

        # pop in the where clause over the top of the values for an escapable where array
        where_array.unshift where_string

        support = SupportHelpdeskSetting.active.where(where_array)[0]

        # cancel processing if there is no support in our system
        if support.nil?
          raise Support::PipelineProcessingSuccessful.new "No support setup exists for any of these email addresses: #{emails.join(", ")}."
        end

        # otherwise add the support to the context
        @context[:support] = support
        @context
      end
    end
  end
end