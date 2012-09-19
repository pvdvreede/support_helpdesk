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
    class IgnoreOwnEmailPipeline < Support::Pipeline::PipelineBase
      def execute
        # get the email
        email = @context[:email]
        support = @context[:support]

        if email.from[0].to_s.downcase == support.to_email_address.downcase
          raise Support::PipelineProcessingWarn.new "Email is from the very address it is meant to be routing: #{email.from[0].to_s}."
        end

        # return context to keep processing
        @context
      end
    end
  end
end