require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::CreateSupportIssue do
  let(:participant)  { Support::Participants::CreateSupportIssue.new }
  let(:email)        { Mail::Message.new(:to => 'support@test.com', :from => 'send@mycompany.com') }
  let(:project)      { FactoryGirl.create(:project, :trackers => [support.tracker]) }
  let(:support)      { FactoryGirl.create(:support_helpdesk_setting) }
  let(:workitem) do
    create_workitem({
      'email'            => email.to_yaml,
      'support_settings' => support.attributes,
      'email_subject'    => 'This is the subject',
      'email_body'       => 'This is the description',
      'related_project'  => project.attributes,
      'email_reply_to'   => 'send@mycompany.com'
    })
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  it 'will create the issue in the database' do
    Issue.where(:subject => workitem.fields['email_subject']).first.should be_nil
    participant.on_workitem
    Issue.where(:subject => $reply.fields['email_subject']).first.should_not be_nil
  end

  it 'will set the issue in the workitem' do
    participant.on_workitem
    $reply.fields['related_issue'].should_not be_nil
    $reply.fields['related_issue']['subject'].should eq $reply.fields['email_subject']
  end

  it 'will use the email_body for the description' do
    participant.on_workitem
    $reply.fields['related_issue']['description'].should eq $reply.fields['email_body']
  end

  it 'will set the reply email with the correct custom field' do
    participant.on_workitem
    issue = Issue.where(:subject => $reply.fields['email_subject']).first
    issue.should_not be_nil
    issue.custom_value_for(support.reply_email_custom_field_id).value.should eq 'send@mycompany.com'
  end

  it 'will set an issue_created in work item' do
    participant.on_workitem
    $reply.fields['issue_created'].should be_true
  end

  it 'will set the correct support id to the issue' do
    participant.on_workitem
    issue = Issue.where(:subject => $reply.fields['email_subject']).first
    issue.support_helpdesk_setting.id.should eq support.id
  end

  it 'will assign the issue to the support setting assignee' do
    participant.on_workitem
    $reply.fields['related_issue']['assigned_to_id'].should eq support.assignee_group_id
  end

  it 'will set the support name in the support custom field' do
    participant.on_workitem
    issue = Issue.where(:subject => $reply.fields['email_subject']).first
    issue.should_not be_nil
    issue.custom_value_for(support.type_custom_field_id).value.should eq support.name
  end

end
