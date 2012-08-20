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
  class Emailer
    def initialize(email=nil)
      @email = email
    end

    def email=(value)
      @email = value
    end

    def email
      @email
    end

    def from_domain
      @email.from[0].split("@")[1]
    end

    def send_email(issue, &block)
      notes = nil
      begin
        mail = block.call
        @email = mail
      rescue Exception => e
        Support.log_error "There was an error and the email was not sent because #{e}.\n#{e.backtrace}"
        notes = "There was an error and the email was not sent because #{e}"
      else
        self.attach_email(
          issue,
          "Email sent from Redmine to #{@email.to[0].to_s}"
        )
      end
    end

    def get_email_reply_string(support)
      return @email.from[0] if not support.reply_all_for_outgoing

      #build semicolon string from all fields if not the support email
      email_array = @email.to.to_a + @email.from.to_a + @email.cc.to_a

      email_array.find_all { |e| e.downcase unless e.downcase == support.to_email_address.downcase }.join(";")
    end

    def find_support
      # join all possible emails address into one array for looping
      emails = @email.to.to_a + @email.cc.to_a + @email.bcc.to_a
      where_string = ""
      where_array = []
      emails.each do |e|
        where_string += "LOWER(to_email_address) LIKE ?"
        where_string += " OR " unless emails.last == e
        where_array.push "%#{e.downcase}%"
      end

      # pop in the where clause over the top of the values for an escapable where array
      where_array.unshift where_string

      SupportHelpdeskSetting.active.where(where_array)[0]
    end

    def attach_email(issue, description)
      #add attachment
      attachment = Attachment.new(
        :file         => @email.encoded,
        :author       => User.find(issue.support_helpdesk_setting.author_id),
        :content_type => "message/rfc822",
        :filename     => "#{@email.from[0].to_s.downcase}_to_#{@email.to[0].to_s.downcase}.eml",
        :container    => issue,
        :description  => description
      )
      
      unless attachment.save
        raise ActiveRecord::Rollback
      end

      # add a note to the issue with email body
      journal = Journal.new(
        :journalized_id   => issue.id,
        :journalized_type => "Issue",
        :notes            => "",
        :user_id          => issue.support_helpdesk_setting.author_id
      )

      unless journal.save
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

      self.add_message_id(issue, issue.support_helpdesk_setting, attachment)
    end

    def add_message_id(issue, support, attachment)
      # create the message id from the email and relate it to the issue and support
      support_message_id = IssuesSupportMessageId.create!(
        :issue_id => issue.id,
        :support_helpdesk_setting_id => support.id,
        :message_id => @email.message_id,
        :attachment_id => attachment.id
      )

      # get the parent and add to it
      if !@email.reply_to.nil?
        parent_message = IssuesSupportMessageId.where(:message_id => @email.reply_to)[0]
      elsif !@email.references.nil?
        parent_message = IssuesSupportMessageId.where(:message_id => @email.references)[0]
      end
      support_message_id.move_to_child_of(parent_message) unless parent_message.nil?

      #save the message id
      unless support_message_id.save
        Support.log_error "Error saving support message id because #{issue.errors.full_messages.join("\n")}"
        raise ActiveRecord::Rollback
      end
    end

    def get_email_body_text
      begin
        html_encode = false
        if @email.text_part.nil? == false
          part = email.text_part
        elsif @email.html_part.nil? == false
          part = @email.html_part
          html_encode = true
        else
          raise TypeError.new "Email does not have text or html part."
        end

        case part.body.encoding
        when "base64"
          body = Base64.decode64(part.body.raw_source)
        else
          body = part.body.raw_source
        end

        if html_encode
          body = CGI.unescapeHTML(body)
        end
      rescue => ex
        Support.log_error "Exception trying to load email body so using static text: #{ex}"
        body = "Could not decode email body. Email body in attached email."
      end
      body
    end
  end
end