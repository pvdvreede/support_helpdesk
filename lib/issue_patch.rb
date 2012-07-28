module Support
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do 
        unloadable

        # add filter checking the status on issue save
        after_save :check_and_send_ticket_close
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def check_and_send_ticket_close
        ::Rails.logger.debug "Checking issue for Support emails..."
        return unless self.tracker.name == "Ticket"
        ::Rails.logger.debug "Issue #{self.id} change and tracker is Ticket."  
        if self.status.is_closed?
          # TODO fix this as it doesnt check whether the status just change or not!
          ::Rails.logger.debug "Issue #{self.id} status is closed."
          reply_field = CustomValue.where(:customized_id => self, :custom_field_id => IssueCustomField.where(:name => "Reply Address"))[0]
          SupportMailHandler.ticket_closed(self, reply_field.value).deliver \
           unless reply_field == nil or reply_field.value == nil
        end
      end
    end
  end
end

Issue.send(:include, Support::IssuePatch)