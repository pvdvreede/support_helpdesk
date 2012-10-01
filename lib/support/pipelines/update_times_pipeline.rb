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
    class UpdateTimesPipeline < Support::Pipeline::PipelineBase

      def execute
        # update the issue updated_at time
        issue = @context[:issue]
        issue.updated_on = Time.now
        issue.save!

        # update the support last processed time
        support = @context[:support]
        support.last_processed = Time.now
        support.save!

        @context
      end

    end
  end
end