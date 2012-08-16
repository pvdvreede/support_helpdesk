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

# TODO refactor test suite to use DRY properly
require File.dirname(File.expand_path(__FILE__)) + '/../test_helper'

class SupportHelpdeskMailerTest < ActionMailer::TestCase
  self.fixture_path = File.dirname(File.expand_path(__FILE__)) + "/../fixtures/"
  fixtures :all

  def test_false_when_no_supports
    # load email into string
    mail = load_email "multipart_email.eml"
    mail.to = "not@item.com"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive mail
    assert !result, "Should be false as the email is not part of support items"
  end

  def test_false_when_support_inactive
    mail = load_email "multipart_email.eml"
    mail.to = "test3@support.com"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive mail
    assert !result, "Should have return false for inactive support"
  end

  def test_creation_issue_01 

    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = "test@support.com"

    # pass to handler
    start_time = Time.now
    handler = SupportMailHandler.new
    result = handler.receive mail
    assert result, "Should have created issue and returned true"
    end_time = Time.now

    # check the issue is there with the correct settings
    issue = check_issue_created mail, 3, "supp01", 1, 1, 2

    # check to see if the email was sent including email to assignee
    assert_equal 1, ActionMailer::Base.deliveries.count, "Creation email not sent"

    # check email is correct
    email = ActionMailer::Base.deliveries[0]

    assert_equal 1, email.to.count, "Incorrect amount of emails in reply"
    assert_equal "test@david.com", email.to[0], "Email to sent out isnt correct"
    assert_equal "reply@support.com", email.from[0], "Email from sent out isnt correct"

    # make sure the mail is being sent with the name
    assert_not_nil email.encoded =~ /From: Name <reply@support.com>/, "The email is not being sent with a name in the from."

    # make sure the processed and run time where updated
    check_support_times_updated 1, start_time, end_time

    issue
  end

  def test_creation_issue_02
    mail = load_email "multipart_email.eml"
    mail.from = "test@james.org"
    mail.to = "test2@support.com"

    # pass to handler
    start_time = Time.now
    handler = SupportMailHandler.new
    result = handler.receive mail
    assert result, "Should have created issue"
    end_time = Time.now

    # check the issue is there with the correct settings
    issue = check_issue_created mail, 3, "supp02", 2, 2, 1

    # check to see if the email was sent, shouldnt have cause set to false
    assert_equal 0, ActionMailer::Base.deliveries.count, "Creation email was sent when it shouldnt have"

    # make sure the processed and run time where updated
    check_support_times_updated 2, start_time, end_time

    issue
  end
  
  def test_creation_issue_04
    mail = load_email "multipart_email.eml"
    mail.from = "test@none.org"
    mail.to = "test4@support.com"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive mail
    assert result, "Should have created issue"

    # check the issue is there with the correct settings
    check_issue_created mail, 3, "supp04", 4, 2, 3

    # check to see if the email was sent, shouldnt have cause set to false
    assert_equal 1, ActionMailer::Base.deliveries.count, "Creation email wasnt sent"    
  end

  def test_creation_in_to_with_multiple_emails
    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = ["test@support.com", "another@random.com"]
    mail.cc = "cced@another.com"

    # pass to handler
    start_time = Time.now
    handler = SupportMailHandler.new
    result = handler.receive mail
    assert result, "Should have created issue and returned true"
    end_time = Time.now

    # check the issue is there with the correct settings
    issue = check_issue_created mail, 3, "supp01", 1, 1, 2

    # check to see if the email was sent including email to assignee
    assert_equal 1, ActionMailer::Base.deliveries.count, "Creation email not sent"

    # check email is correct
    email = ActionMailer::Base.deliveries[0]

    assert_equal "test@david.com", email.to[0], "Email to sent out isnt correct"
    assert_equal "reply@support.com", email.from[0], "Email from sent out isnt correct"

    # make sure the mail is being sent with the name
    assert_not_nil email.encoded =~ /From: Name <reply@support.com>/, "The email is not being sent with a name in the from."

    # make sure the processed and run time where updated
    check_support_times_updated 1, start_time, end_time

    issue
  end

  def test_creation_in_cc_with_multiple_emails
    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = ["to2@random.com", "another@random.com"]
    mail.cc = ["tEst@suPpOrt.com", "cced@another.com"]

    # pass to handler
    start_time = Time.now
    handler = SupportMailHandler.new
    result = handler.receive mail
    assert result, "Should have created issue and returned true"
    end_time = Time.now

    # check the issue is there with the correct settings
    issue = check_issue_created mail, 3, "supp01", 1, 1, 2

    # check to see if the email was sent including email to assignee
    assert_equal 1, ActionMailer::Base.deliveries.count, "Creation email not sent"

    # check email is correct
    email = ActionMailer::Base.deliveries[0]

    assert_equal "test@david.com", email.to[0], "Email to sent out isnt correct"
    assert_equal "reply@support.com", email.from[0], "Email from sent out isnt correct"

    # make sure the mail is being sent with the name
    assert_not_nil email.encoded =~ /From: Name <reply@support.com>/, "The email is not being sent with a name in the from."

    # make sure the processed and run time where updated
    check_support_times_updated 1, start_time, end_time

    issue
  end

  def test_reply_all_on_creation
    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = ["to2@random.com", "another@random.com"]
    mail.cc = ["tEst5@suPpOrt.com", "cced@another.com"]

    # pass to handler
    start_time = Time.now
    handler = SupportMailHandler.new
    result = handler.receive mail
    assert result, "Should have created issue and returned true"
    end_time = Time.now

    # check the issue is there with the correct settings
    issue = check_issue_created mail, 3, "supp05", 5, 2, 3

    # check to see if the email was sent including email to assignee
    assert_equal 1, ActionMailer::Base.deliveries.count, "Creation email not sent"

    # check email is correct
    email = ActionMailer::Base.deliveries[0]

    assert_equal 4, email.to.count, "Incorrect amount of emails in reply"
    assert_equal "reply5@support.com", email.from[0], "Email from sent out isnt correct"

    # make sure the processed and run time where updated
    check_support_times_updated 5, start_time, end_time

    issue
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

  def check_support_times_updated(id, start_time, end_time)
    start_time = start_time.advance :seconds => -1
    end_time = end_time.advance :seconds => 1
    support = SupportHelpdeskSetting.find id
    assert_not_nil support.last_processed, "Last processed not populated"    
    assert (start_time <= support.last_processed), "Last processed not updated"
    assert (end_time >= support.last_processed), "Last process not updated"
  end

  def check_issue_created(email, tracker_id, support_name, support_id, assignee, project_id)
    # check the issue is there with the correct settings
    issue = Issue.where(:subject => email.subject).where(:tracker_id => tracker_id)[0]

    assert_not_nil issue, "Issue not created"
    assert_not_nil issue.start_date, "Start date not added in"

    # make sure the assignee is correct
    assert_equal assignee, issue.assigned_to_id, "Issue not assigned correctly"

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

    #assert_equal , issue.reply_email, "Not getting reply address from issue patch correctly"
    assert_equal support_name, issue.support_type,  "Not getting support type from issue patch correctly"

    # check correct project is selected
    assert_equal project_id, issue.project_id, "Project was not assigned properly"

    issue
  end

  def check_issue_updated(issue, tracker_id)
    assert_not_nil issue, "Issue not created"

    # make sure there is a notes entry with an updated comment
    note = Journal.where(:journalized_id => issue.id).where(:journalized_type => "Issue").where("notes LIKE ?", "%Email received from%")[0]

    assert_not_nil note, "Update did not create Journal entry for issue"
  end
end