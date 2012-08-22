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

# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

def load_email(file)
  # load email into string
  email_file = File.open File.dirname(__FILE__) + "/emails/#{file}"
  email_string = email_file.read
  email = Mail.new email_string
end

def create_issue(mail, tracker_id, support_id, assignee, project_id, created=true)
  # pass to handler
  start_time = Time.now
  handler = SupportMailHandler.new
  result = handler.receive mail

  issue = Issue.where(:subject => mail.subject). \
                  where(:tracker_id => tracker_id). \
                  where(:project_id => project_id). \
                  where(:assigned_to_id => assignee)[0]

  if created
    assert result, "Handler should have created issue and returned true"
    assert_not_nil issue, "Issue not created when it should have"
  else
    #assert !result, "Handler should have returned false"
    # make sure no issue was created
  
    assert_nil issue, "Issue was created when it should not have been."
    return
  end

  end_time = Time.now

  support = SupportHelpdeskSetting.find support_id

  # check the issue is there with the correct settings
  issue = check_issue_created mail, tracker_id, support.name, support.id, assignee, project_id

  # check to see if the email was sent including email to assignee
  assert_equal (support.send_created_email_to_user ? 1 : 0), ActionMailer::Base.deliveries.count, "Creation email error"

  if support.send_created_email_to_user
    # check email is correct
    email = ActionMailer::Base.deliveries[0]

    #assert_equal mail.to.count, email.to.count, "Incorrect amount of emails in reply"
    #assert_equal mail.from[0], email.to[0], "Email to sent out isnt correct"
    assert (support.from_email_address.to_s.include?(email.from[0].to_s)), "Email from sent out isnt correct"      
  end

  # make sure the processed and run time where updated
  check_support_times_updated support, start_time, end_time

  # make sure the message id was added from the email
  message = issue.issues_support_message_id.root
  assert_not_nil message, "Email message id was inserted"
  assert_equal mail.message_id, message.message_id, "Email message id wasnt inserted"

  # make sure the message id was added for return mail if its set
  if support.send_created_email_to_user
    created_id = issue.issues_support_message_id.root.children[0]
    assert_not_nil created_id, "Created email message id not created"
  end

  return issue, email
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

def check_support_times_updated(support, start_time, end_time)
  start_time = start_time.advance :seconds => -1
  end_time = end_time.advance :seconds => 1
  assert_not_nil support.last_processed, "Last processed not populated"    
  assert (start_time <= support.last_processed), "Last processed not updated"
  assert (end_time >= support.last_processed), "Last process not updated"
end

def check_issue_updated(issue, mail, tracker_id)
  assert_not_nil issue, "Issue not created"

  # make sure there is a notes entry with an updated comment
  note = Journal.where(:journalized_id => issue.id).where(:journalized_type => "Issue").where("notes LIKE ?", "%Email received from #{mail.from[0]}%")[0]

  assert_not_nil note, "Update did not create Journal entry for issue"

  # make sure a message id has been created for the email
  messages = issue.issues_support_message_id

  assert messages.count > 1, "There is only one message id for issue"
  message = messages.detect { |x| x.message_id == mail.message_id }
  assert_not_nil message, "Message id for update mail wasnt added"
end
