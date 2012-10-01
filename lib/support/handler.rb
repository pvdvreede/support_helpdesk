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
  PipelineProcessingSuccessful = Class.new(Exception)
  PipelineProcessingWarn = Class.new(Exception)
  PipelineProcessingError = Class.new(Exception)

  class Handler
    # class var for pipelines to run
    @@pipelines = []

    public
    def self.pipelines=(value)
      @@pipelines = value
    end

    # Send email to handler to process. The handler will return one of the following:
    # 0 = Successful processing and email should be deleted
    # 1 = Unsuccesful processing but email should be deleted if option is set
    # 2 = Processing had an error and the email should NOT be deleted
    def receive(email, options={})
      #create the context for the pipelines
      context = { :email => email, :options => options }

      begin
        Support.log_info "Running pipelines..."
        execute_pipelines(context)
      rescue Exception => e
        Support.log_error "There was an error executing the pipelines: #{e}."
        Support.log_debug "Error backtrace:\n#{e.backtrace}"
        # There was a massive error and the email should NOT be deleted
        return 2
      end
    end

    private
    def execute_pipelines(context)
      status = 0

      # wrap in a transaction
      ActiveRecord::Base.transaction do
        @@pipelines.each do |pipeline|
          pipeline.context = context
          if pipeline.should_run?
            begin
              Support.log_info "Running #{pipeline.name} pipeline..."
              context = pipeline.execute
            rescue Support::PipelineProcessingWarn => e
              Support.log_warn e
              return 1
            rescue Support::PipelineProcessingError => e
              Support.log_error "There was an error in #{pipeline.name}: #{e}."
              Support.log_debug "Error backtrace:\n#{e.backtrace}"
              raise ActiveRecord::Rollback
              return 2
            rescue Support::PipelineProcessingSuccessful => e
              Support.log_info "Pipeline #{pipeline.name} marked the email as successfully processed because: #{e}."
              return 0
            end
            
            # log context for debugging
            Support.log_debug "Context object: #{context.keys.join(', ')}"
          else
            Support.log_info "Pipeline #{pipeline.name} is not being run."
          end

          
        end
      end

      Support.log_info "All pipelines successfully run." if status == 0
      status
    end
  end
end