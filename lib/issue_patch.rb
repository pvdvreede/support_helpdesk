module Support
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do 
        unloadable

        # add filter checking the status on issue save
        after_save :check_and_send_ticket_close

        # add link to support item for each issue
        has_one :issues_support_setting
        has_one :support_helpdesk_setting, :through => :issues_support_setting
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

      def reply_email
        setting = self.support_helpdesk_setting
        return nil if setting == nil
        email = get_custom_support_value setting.reply_email_custom_field_id
        email.value
      end

      def reply_email=(value)
        setting = self.support_helpdesk_setting
        return if setting == nil
        if self.reply_email == nil
          set_custom_support_value(setting.reply_email_custom_field_id, value)
        else
          email = self.custom_field_values.detect {|x| x.custom_field_id == setting.reply_email_custom_field_id }
          email.value = value.to_s
        end
      end

      def support_type
        setting = self.support_helpdesk_setting
        return nil if setting == nil
        type = get_custom_support_value setting.type_custom_field_id
        type.value
      end

      def support_type=(value)
        setting = self.support_helpdesk_setting
        return if setting == nil
        if self.reply_email == nil
          set_custom_support_value(setting.type_custom_field_id, value)
        else
          type = self.custom_field_values.detect {|x| x.custom_field_id == setting.type_custom_field_id }
          type.value = value.to_s
        end
      end

      def get_custom_support_value(id)
        setting = self.support_helpdesk_setting
        return nil if setting == nil
        custom_value = self.custom_field_values.detect {|x| x.custom_field_id == id }
      end

      def set_custom_support_value(id, value)
        value = CustomFieldValue.new
        value.customized = self
        value.custom_field = CustomField.find(id)
        value.value = value.to_s
        self.custom_field_values << value
        value
      end
    end
  end
end

Issue.send(:include, Support::IssuePatch)