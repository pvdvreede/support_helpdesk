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
    class IgnorePipeline < Support::Pipeline::PipelineBase
      def execute(context)
        # get the email
        email = context[:email]

        if email.subject.nil?
          Support.log_info "Email from #{email.from[0]} has no subject line so one has been added."
          email.subject = "Email had no subject line."
          context[:email] = email
          return context
        end

        subject_start_ignores = [/^auto:.*/, /^out of office:.*/, /^automatic reply:.*/]
        subject_start_ignores.each do |ig|
          unless email.subject.downcase.match(ig).nil?
            raise Support::PipelineProcessingSuccessful.new "Email with subject '#{email.subject}' matches the ignore reg ex '#{ig.to_s}'."
          end
        end

        # return true to keep processing
        context
      end
    end
  end
end