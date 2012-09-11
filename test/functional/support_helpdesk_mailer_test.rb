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
    handler = Support::Handler.new
    result = handler.receive mail
    assert_equal  1, result, "Should be 1 as the email is not part of support items"

    create_issue mail, 3, 1, 1, 2, false
  end

  def test_false_when_support_inactive
    mail = load_email "multipart_email.eml"
    mail.to = "test3@support.com"

    # pass to handler
    handler = Support::Handler.new
    result = handler.receive mail
    assert_equal 1, result, "Should have return 1 for inactive support"

    create_issue mail, 3, 1, 1, 2, false
  end

  def test_creation_issue_01
    mail = load_email "multipart_email.eml"
    mail.from = ["test@david.com"]
    mail.to = ["test@support.com"]

    create_issue mail, 3, 1, 1, 2
  end

  def test_creation_issue_02
    mail = load_email "multipart_email.eml"
    mail.from = ["test@james.org"]
    mail.to = ["test2@support.com"]

    create_issue mail, 3, 2, 2, 1
  end

  def test_creation_issue_04
    mail = load_email "multipart_email.eml"
    mail.from = "test@none.org"
    mail.to = "test4@support.com"

    create_issue mail, 3, 4, 2, 3
  end

  def test_creation_in_to_with_multiple_emails
    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = ["test@support.com", "another@random.com"]
    mail.cc = "cced@another.com"

    issue, email = create_issue mail, 3, 1, 1, 2

    # make sure the mail is being sent with the name
    assert_not_nil email.encoded =~ /From: Name <reply@support.com>/, "The email is not being sent with a name in the from."
  end

  def test_email_ignored_from_domain
    mail = load_email "multipart_email.eml"
    mail.from = "test@ignore.com"
    mail.to = "test5@support.com"

    create_issue mail, 3, 5, 1, 1, false
  end

  def test_email_ignored_from_domain_part
    mail = load_email "multipart_email.eml"
    mail.from = "test@dontignore.com"
    mail.to = "test5@support.com"

    create_issue mail, 3, 5, 1, 1, false
  end

  def test_proper_decoding_singlepart_email
    mail = load_email "singlepart_email.eml"
    mail.from = "test@none.org"
    mail.to = "test4@support.com"

    # pass to handler
    handler = Support::Handler.new
    result = handler.receive mail
    assert result, "Should have created issue"

    # check the issue is there with the correct settings
    issue = check_issue_created mail, 3, "supp04", 4, 2, 3

    #check description
    # html decoding is disabled as it doesn't render the html unescaped
    assert_equal "Could not decode email body. Email body in attached email.", issue.description, "Single part email not properly decoded"

    # check to see if the email was sent, shouldnt have cause set to false
    assert_equal 1, ActionMailer::Base.deliveries.count, "Creation email wasnt sent"

  end

  def test_email_ignored_from_domain_substring
    mail = load_email "multipart_email.eml"
    mail.from = "test@nore.com"
    mail.to = "test5@support.com"

    create_issue mail, 3, 5, 1, 1, false
  end

  def test_creation_in_cc_with_multiple_emails
    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = ["to2@random.com", "another@random.com"]
    mail.cc = ["tEst@suPpOrt.com", "cced@another.com"]

    issue, email = create_issue mail, 3, 1, 1, 2
  end

  def test_reply_all_on_creation
    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = ["to2@random.com", "another@random.com"]
    mail.cc = ["tEst5@suPpOrt.com", "cced@another.com"]

    issue, email = create_issue mail, 3, 5, 2, 3

    assert_equal 4, email.to.count, "Incorrect amount of emails in reply"
    assert_equal "reply5@support.com", email.from[0], "Email from sent out isnt correct"
  end


  def test_address_in_from_and_cc
    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = ["to2@random.com"]
    mail.cc = ["tEst5@suPpOrt.com", "test@david.com", "cced@another.com"]

    issue, email = create_issue mail, 3, 5, 2, 3
  end

  def test_address_in_from_and_to
    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = ["to2@random.com", "test@david.com"]
    mail.cc = ["tEst5@suPpOrt.com", "cced@another.com"]

    issue, email = create_issue mail, 3, 5, 2, 3
  end

  def test_ignored_subject_lines
    mail = load_email "multipart_email.eml"
    mail.from = "test@david.com"
    mail.to = ["to2@random.com", "another@random.com"]
    mail.cc = ["tEst5@suPpOrt.com", "cced@another.com"]
    mail.subject = "Auto: The subject line"

    create_issue mail, 3, 5, 2, 3, false

    mail.subject = "Out of Office: this another subject"
    create_issue mail, 3, 5, 2, 3, false

    mail.subject = "AUtomatic rEPLY: this is another subject"
    create_issue mail, 3, 5, 2, 3, false

    mail.subject = "AUtomatic rEPLY:"
    create_issue mail, 3, 5, 2, 3, false

    mail.subject = "The auto: isnt at the start"
    create_issue mail, 3, 5, 2, 3
  end

  def test_update_issue_01
    mail = load_email "multipart_email.eml"
    mail.from = "test@hello.com"
    mail.to = "test@support.com"

    issue, email = create_issue mail, 3, 1, 1, 2

    # pause so there is diff in update time
    sleep 2

    update_email = load_email "multipart_email.eml"
    update_email.subject = "Re: #{email.subject}"

    # pass to handler
    handler = Support::Handler.new
    result = handler.receive update_email
    assert result, "Should have updated issue and returned true"

    check_issue_updated issue, update_email, 3
  end

  def test_update_from_references
    mail = load_email "multipart_email.eml"
    mail.from = "test@hello.com"
    mail.to = "test@support.com"

    issue, email = create_issue mail, 3, 1, 1, 2

    # pause so there is diff in update time
    sleep 2

    update_mail = load_email "multipart_email_related.eml"
    update_mail.from = "test@hello.com"
    update_mail.to = "test@support.com"

    # pass to handler
    handler = Support::Handler.new
    result = handler.receive update_mail
    assert result, "Should have updated issue and returned true"

    check_issue_updated issue, update_mail, 3
  end

end