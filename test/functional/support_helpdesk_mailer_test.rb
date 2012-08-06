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

  def test_creation_issue_01 
    email = load_email "multipart_email.eml"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive email
    assert result, "Should have created issue"

    # check the issue is there with the correct settings

    # check to see if the email was sent
    assert !ActionMailer::Base.deliveries.empty?, "Creation email not sent"
  end

  def test_creation_issue_02
    email = load_email "multipart_email.eml"
    email.to = "test2@support.com"

    # pass to handler
    handler = SupportMailHandler.new
    result = handler.receive email
    assert result, "Should have created issue"

    # check the issue is there with the correct settings

    # check to see if the email was sent, shouldnt have cause set to false
    assert ActionMailer::Base.deliveries.empty?, "Creation email was sent when it shouldnt have"
  end

  def test_update_issue
    flunk "Not implemented"
  end

  private
  def load_email(file)
    # load email into string
    email_file = File.open File.dirname(__FILE__) + "/../emails/#{file}"
    email_string = email_file.read
    email = Mail.new email_string
  end
end