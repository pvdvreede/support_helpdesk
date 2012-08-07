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


class SupportMailHandler
  
  def receive(message, options={})
    begin     
      self.route_email message    
    rescue Exception => e
      Support.log_error "There was an error #{e} processing message:\n#{e.backtrace}\n\n#{message}"
      return false
    end
  end

  def route_email(email)
    # check if it is for a current issue first
    id = check_issue_exists(email)
    if (id != false)
      return update_issue id, email
    end

    # otherwise create a new ticket if there is a support setting for it
    supports = SupportHelpdeskSetting.where("LOWER(to_email_address) LIKE ?", "%#{email.to[0].downcase}%") \
                                     .where(:active => true)

    # if none than ignore the email
    unless supports.count > 0
      Support.log_info "No active support setups match the email address: #{email.to[0]}."
      # tell POP3 to not delete the email,cause it might not be for us
      return false
    end

    return self.create_issue(supports[0], email)
  end

  def check_issue_exists(email)
    # see if this is an update to an existing ticket based on subject
    subject = email.subject
    id = (subject =~ /Ticket #([0-9]*)/ ? $1 : false)
  end

  def create_issue(support, email)
    # TODO put issue creation inside transaction for atomicity

    # get the assignee and update the round robin item
    last_assignee = support.last_assigned_user_id || 0
    this_assignee = get_assignee(support.assignee_group_id, last_assignee)

    # if project_id is nil then get id from domain
    if support.email_domain_custom_field_id != nil
      project_id = get_project_from_email_domain(
        email.from[0].split("@")[1],
        support.email_domain_custom_field_id,
        support.project_id
      )
    else
      project_id = support.project_id
    end

    begin
      body = email.text_part.body.raw_source
    rescue => ex
      Support.log_error "Exception trying to load email body so using static text: #{ex}"
      body = "Ticket generated from attached email."
    end

    issue = Issue.new({:subject => email.subject, 
                      :tracker_id => support.tracker_id,
                      :project_id => project_id,
                      :description => body, 
                      :author_id => support.author_id, 
                      :status_id => support.new_status_id, 
                      :assigned_to_id => this_assignee})
    support.last_assigned_user_id = this_assignee
    support.save
    issue.support_helpdesk_setting = support
    issue.reply_email = email.from[0]
    issue.support_type = support.name

    if not issue.save
      Support.log_error "Error saving issue because #{issue.errors.full_messages.join("\n")}"
    end

    # send attachment to redmine
    SupportMailHandler.attach_email(
      issue, 
      email.encoded, 
      "#{email.from[0]}_#{email.to[0]}.eml",
      "Email issue was created from."
     )

    # send email back to ticket creator if it has been request
    if support.send_created_email_to_user
      begin
        mail = SupportHelpdeskMailer.ticket_created(issue, email.from[0]).deliver
      rescue Exception => e
        Support.log_error "Error in sending email for #{issue.id}: #{e}\n#{e.backtrace.join("\n")}"
        email_status = "Error sending ticket creation email, email was *NOT* sent."
      else
        email_status = "Emailed ticket creation to #{email.from[0]} at #{Time.now.to_s}."

        # save the email sent for our records
        SupportMailHandler.attach_email(
            issue,
            mail.encoded,
            "#{mail.from}_#{mail.to}.eml",
            "Ticket created email sent to user."
          )
      end

      # add a note to the issue so we know the closing email was sent
      journal = Journal.new
      journal.notes = email_status
      journal.user_id = support.author_id
      issue.journals << journal
    end

    # update the last run for the support
    support.last_processed = Time.now.utc
    return true
  end

  def update_issue(issue_id, email)
    issue = Issue.find issue_id

    # attach the email to the issue
    SupportMailHandler.attach_email(
      issue, 
      email.encoded, 
      "#{email.from[0]}_#{email.to[0]}.eml",
      "Email from #{email.from[0]}."
    )

    # add a note to the issue with email body
    journal = Journal.new
    journal.notes = "Email received from #{email.from[0]} at #{Time.now.to_s} and is attached."
    journal.user_id = issue.support_helpdesk_setting.author_id
    issue.journals << journal
    if not issue.save
      Support.log_error "Could not save issue #{issue.errors.full_messages.join("\n")}"
      return false
    end

    # update processed time
    issue.support_helpdesk_setting.last_processed = Time.now.utc

    return true
  end

  # use round robin
  def get_assignee(group_id, last_id)
    users = Group.find(group_id).users.order("id")
    ::Rails.logger.debug "There are #{users.count} users in the group."
    user_count = users.count
    return if user_count == 0
    return users[0].id if user_count == 1
    return users[0].id if last_id == 0 
    users.each_with_index do |u, i|
      if u.id == last_id
        if i+1 == user_count
          return users[0].id
        else
          return users[i+1].id
        end
      end
    end
  end

  def get_project_from_email_domain(domain, field_id, default_project_id)
    # search for the project
    projects = Project.joins(:custom_values).
                       where("#{CustomValue.table_name}.custom_field_id = ?", field_id).
                       where("#{CustomValue.table_name}.value = ?", domain)
    return default_project_id if projects.empty?
    return projects[0].id
  end

  def self.attach_email(issue, email_string, filename, description=nil)
    attachment = Attachment.new(:file => email_string)
    attachment.author = User.where(:id => 1)[0]
    attachment.content_type = "message/rfc822"
    attachment.filename = filename
    attachment.container = issue
    attachment.description = description if description
    attachment.save
  end

end

require File.dirname(__FILE__) + '/../test_helper'

class SupportHelpdeskMailerTest < ActionMailer::TestCase
  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :all

  def test_false_when_no_supports
    # load email into string
    email = load_email "multipart_email.eml"
    email.to = "not@item.com"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive email
    assert !result, "Should be false as the email is not part of support items"
  end

  def test_false_when_support_inactive
    email = load_email "multipart_email.eml"
    email.to = "test3@support.com"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive email
    assert !result, "Should have return false for inactive support"
  end

  def test_creation_issue_01 
    email = load_email "multipart_email.eml"
    email.to = "test@support.com"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive email
    assert result, "Should have created issue and returned true"

    # check the issue is there with the correct settings
    issue = check_issue_created email, 3, "supp01", 1

    # check to see if the email was sent including email to assignee
    assert_equal 1, ActionMailer::Base.deliveries.count, "Creation email not sent"

    # check email is correct
    email = ActionMailer::Base.deliveries[0]

    assert_equal "thetester@somewhere.com", email.to[0], "Email to sent out isnt correct"
    assert_equal "reply@support.com", email.from[0], "Email from sent out isnt correct"

    issue
  end

  def test_creation_issue_02
    email = load_email "multipart_email.eml"
    email.to = "test2@support.com"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive email
    assert result, "Should have created issue"

    # check the issue is there with the correct settings
    check_issue_created email, 3, "supp02", 2

    # check to see if the email was sent, shouldnt have cause set to false
    assert_equal 0, ActionMailer::Base.deliveries.count, "Creation email was sent when it shouldnt have"
  end
  
  def test_update_issue_01
    # run a create
    issue = test_creation_issue_01

    assert_not_nil issue, "Creation for update didnt work"

    # then get the email and grab the subject to resend
    email = ActionMailer::Base.deliveries[0]
    update_email = load_email "multipart_email.eml"
    update_email.subject = "Re: #{email.subject}"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive email
    assert result, "Should have updated issue and returned true"

    check_issue_updated issue, 3
  end

  private
  def load_email(file)
    # load email into string
    email_file = File.open File.dirname(__FILE__) + "/../emails/#{file}"
    email_string = email_file.read
    email = Mail.new email_string
  end

  def check_issue_created(email, tracker_id, support_name, support_id)
    # check the issue is there with the correct settings
    issue = Issue.where(:subject => email.subject).where(:tracker_id => tracker_id)[0]

    assert_not_nil issue, "Issue not created"

    # check the custom values were inserted
    vs = CustomValue.where(:customized_id => issue.id, :customized_type => "Issue")

    assert_equal 2, vs.count, "Custom values were not inserted properly"

    # check issue custom value join
    assert_equal 2, issue.custom_field_values.count, "Issue custom values joins not working"

    # check that the issues support join was inserted
    join = IssuesSupportSetting.where(:issue_id => issue.id).where(:support_helpdesk_setting_id => support_id)[0]
    assert_not_nil join, "Issue Support join not inserted."

    # check issue support setting patch
    assert_not_nil issue.support_helpdesk_setting, "support setting on issue patch not working correctly"

    assert_equal email.from[0], issue.reply_email, "Not getting reply address from issue patch correctly"
    assert_equal support_name, issue.support_type,  "Not getting support type from issue patch correctly"

    issue
  end

  def check_issue_updated(issue, tracker_id)
    assert_not_nil issue, "Issue not created"

    # make sure there is a notes entry with an updated comment
    note = Journal.where(:journalized_id => issue.id).where(:journalized_type => "Issue").where("notes LIKE ?", "%Email received from%")[0]

    assert_not_nil note, "Update did not create Journal entry for issue"
  end
end