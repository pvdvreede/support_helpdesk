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
	module Helper
		module Attachments

      def add_message_id(email, issue, support, attachment)
        # create the message id from the email and relate it to the issue and support
        support_message_id = IssuesSupportMessageId.create!(
          :issue_id => issue.id,
          :support_helpdesk_setting_id => support.id,
          :message_id => email.message_id,
          :attachment_id => attachment.id
        )

        # get the parent and add to it
        if !email.reply_to.nil?
          parent_message = IssuesSupportMessageId.where(:message_id => email.reply_to).first
        elsif !email.references.nil?
          parent_message = IssuesSupportMessageId.where(:message_id => email.references).first
        end
        support_message_id.move_to_child_of(parent_message) unless parent_message.nil?

        #save the message id
        unless support_message_id.save
          Support.log_error "Error saving support message id because #{issue.errors.full_messages.join("\n")}"
          raise ActiveRecord::Rollback
        end
      end

      def attach_email(email, issue, description)
        filename = "#{email.from[0].to_s.downcase}_#{Time.now.strftime("%Y%m%d%H%M%S")}.eml"

        #add attachment
        attachment = Attachment.new(
          :file         => email.encoded,
          :author       => User.find(issue.support_helpdesk_setting.author_id),
          :content_type => "message/rfc822",
          :filename     => filename,
          :container    => issue,
          :description  => description
        )

        unless attachment.save
          raise ActiveRecord::Rollback
        end

        # add a note to the issue with email body
        journal = Journal.new(
          :notes            => "",
          :user_id          => issue.support_helpdesk_setting.author_id
        )

        issue.journals << journal

        unless journal.save!
          Support.log_error "Could not save journal because:\n#{journal.errors.full_messages.join("\n")}"
          raise ActiveRecord::Rollback
        end

        detail = JournalDetail.new(
          :journal_id => journal.id,
          :property   => "attachment",
          :prop_key   => attachment.id,
          :value      => filename
        )

        unless detail.save
          Support.log_error "Error saving journal detail because #{issue.errors.full_messages.join("\n")}"
          raise ActiveRecord::Rollback
        end

        add_message_id(email, issue, issue.support_helpdesk_setting, attachment)
      end

    end
  end
end