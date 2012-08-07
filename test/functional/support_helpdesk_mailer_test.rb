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