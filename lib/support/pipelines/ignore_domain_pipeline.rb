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
    class IgnoreDomainPipeline < Support::Pipeline::PipelineBase
      def execute(context)
        # get the email
        email = context[:email]

        # make sure support is there
        support = context[:support]

        # if there are no domains to ignore return
        return context if support.domains_to_ignore.nil?
        
        #otherwise split the domains and check
        domain_array = support.domains_to_ignore.downcase.split(";")
        if domain_array.include?(email.from[0].split('@')[1].downcase)
          raise Support::PipelineProcessingSuccessful.new "Email #{email.from[0].to_s} is on the ignored email domain list."
        end
        
        context
      end

    end
  end
end