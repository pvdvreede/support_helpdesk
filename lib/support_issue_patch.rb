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
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do 
        unloadable

        # add filter checking the status on issue save
        after_update :check_and_send_ticket_close

        # add link to support item for each issue
        has_one :issues_support_setting, :dependent => :destroy
        has_one :support_helpdesk_setting, :through => :issues_support_setting

        # add link to email message ids
        has_many :issues_support_message_id
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

        Support.log_info "Issue #{self.id} status changed from #{old_status.name} to #{new_status.name} so sending email."

        begin
          mail = SupportHelpdeskMailer.ticket_closed(self, self.reply_email).deliver
        rescue Exception => e
          Support.log_error "Error in sending email for #{self.id}: #{e}\n#{e.backtrace.join("\n")}"
          email_status = "Error sending closing email, email was *NOT* sent."
        else
          email_status = "Closing email to #{self.reply_email} at #{Time.now.strftime("%d %b %Y %I:%M:%S %p")}."

          # save the email sent for our records
          SupportMailHandler.attach_email(
              self,
              mail.encoded,
              "#{mail.from}_#{mail.to}.eml",
              "Closing email sent to user.",
              self.support_helpdesk_setting.author_id
            )
        end

        # add a note to the issue so we know the closing email was sent
        journal = Journal.new
        journal.notes = email_status
        journal.user_id = self.support_helpdesk_setting.author_id
        self.journals << journal
      end

      def reply_email
        setting = self.support_helpdesk_setting
        return nil if setting == nil
        email = get_custom_support_value setting.reply_email_custom_field_id
        return nil if email == nil
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
        return nil if type == nil
        type.value
      end

      def support_type=(value)
        setting = self.support_helpdesk_setting
        return if setting == nil
        if self.support_type == nil
          set_custom_support_value(setting.type_custom_field_id, value)
        else
          type = self.custom_field_values.detect {|x| x.custom_field_id == setting.type_custom_field_id }
          type.value = value.to_s
        end
      end

      def can_send_item?
        reply_email = self.reply_email
        return false if reply_email == nil or reply_email == ""
        return true
      end

      def get_custom_support_value(id)
        custom_value = self.custom_field_values.detect {|x| x.custom_field_id == id }
      end

      def set_custom_support_value(id, value)
        value_field = CustomFieldValue.new
        value_field.customized = self
        value_field.custom_field = CustomField.find(id)
        value_field.value = value.to_s
        self.custom_field_values << value_field
        value_field
      end
    end
  end
end

Issue.send(:include, Support::IssuePatch)