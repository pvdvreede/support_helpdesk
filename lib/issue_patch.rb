module Support
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do 
        unloadable

        # add filter checking the status on issue save
        after_update :check_and_send_ticket_close

        # add link to support item for each issue
        has_one :issues_support_setting
        has_one :support_helpdesk_setting, :through => :issues_support_setting
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def check_and_send_ticket_close
        # only worry about issues that have a support setting
        return if (self.reply_email == nil or self.reply_email == "")
        # only worry if the status is closed and wasnt before
        return unless self.status_id_changed?
        # ignore if the support setting is not asking for closed emails
        return unless self.support_helpdesk_setting.send_closed_email_to_user

        old_status = IssueStatus.find self.status_id_was
        new_status = IssueStatus.find self.status_id
        return unless new_status.is_closed? and not old_status.is_closed?

        ::Rails.logger.info "Issue #{self.id} status changed from #{old_status.name} to #{new_status.name} so sending email."
        SupportHelpdeskMailer.ticket_closed(self, self.reply_email).deliver
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