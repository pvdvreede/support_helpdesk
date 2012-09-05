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
  # create Error classes
  class PipelineProcessingSuccessful < Exception
  end

  class PipelineProcessingError < Exception
  end

  class Handler
    # class var for pipelines to run
    @@pipelines = []

    public
    def self.pipelines=(value)
      @@pipelines = value
    end

    def receive(email, options={})
      #create the context for the pipelines
      context = { :email => email, :options => options }

      begin
        Support.log_info "Running pipelines..."
        execute_pipelines(context)
      rescue Exception => e
        Support.log_error "There was an error executing the pipelines: #{e}."
        Support.log_debug "Error backtrace:\n#{e.backtrace}"
        return false
      end
    end

    private
    def execute_pipelines(context)
      status = true

      # wrap in a transaction
      ActiveRecord::Base.transaction do
        @@pipelines.each do |pipeline|
          pipeline.context = context
          if pipeline.should_run?
            begin
              Support.log_info "Running #{pipeline.name} pipeline..."
              context = pipeline.execute
            rescue Support::PipelineProcessingError => e
              Support.log_error "There was an error in #{pipeline.name}: #{e}."
              Support.log_debug "Error backtrace:\n#{e.backtrace}"
              status = false
              raise ActiveRecord::Rollback
            rescue Support::PipelineProcessingSuccessful => e
              Support.log_info "Pipeline #{pipeline.name} marked the email as successfully processed because: #{e}."
              return true
            end
          else
            Support.log_info "Pipeline #{pipeline.name} is not being run."
          end
        end
      end

      Support.log_info "All pipelines successfully run." if status
      status
    end
  end
end