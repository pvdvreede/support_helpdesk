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
    class GetProjectPipeline < Support::Pipeline::PipelineBase

      def should_run?
        # run if this email isnt an update
        @context.has_key?(:update) == false
      end

      def execute
        support = @context[:support]
        email = @context[:email]

        # search for the project
        email_domain = get_email_domain(email.from[0].to_s)

        projects = Project.joins(:custom_values). \
                           where("#{CustomValue.table_name}.custom_field_id = ?", support.email_domain_custom_field_id). \
                           where("LOWER(#{CustomValue.table_name}.value) like ?", "%#{email_domain}%"). \
                           limit(2)
        if projects.empty? || projects.count > 1
          @context[:project] = Project.find(support.project_id)
        else
          @context[:project] = projects[0]
        end
        @context
      end

      private
        def get_email_domain(address)
          address.downcase.split("@")[1]
        end
    end
  end
end