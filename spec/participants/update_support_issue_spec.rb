require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::UpdateSupportIssue do
  let(:participant) { Support::Participants::UpdateSupportIssue.new }
  let(:email)       { Mail::Message.new(:to => 'support@test.com', :from => 'send@test.com') }
  let(:issue)       { FactoryGirl.create(:issue, :support_helpdesk_setting => support) }
  let(:support)     { FactoryGirl.create(:support_helpdesk_setting) }
  let(:workitem)do
    create_workitem({
      'email'            => email.to_yaml,
      'support_settings' => support.attributes,
      'related_issue'    => issue.attributes,
      'email_body'       => 'This is the email body'
    })
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  it 'add a new journal entry' do
    issue.journals.should be_empty
    participant.on_workitem
    issue.journals.count.should eq 1
  end

  it 'adds who it was recieved from' do
    participant.on_workitem
    issue.journals.first.notes.should include("send@test.com")
  end

  it 'adds the body of the email' do
    participant.on_workitem
    issue.journals.first.notes.should include("This is the email body")
  end

  it 'should set the journal entry to the support setting user' do
    participant.on_workitem
    issue.journals.first.user_id.should eq support.author_id
  end

  it 'should update the updated_at field of the issue' do
    old_updated = issue.updated_on
    sleep 1
    participant.on_workitem
    issue.reload
    issue.updated_on.should > old_updated
  end

  it 'should attach the journal to the work item context' do
    participant.on_workitem
    $reply.fields['related_journal'].should_not be_nil
    $reply.fields['related_journal']['id'].should eq issue.journals.first.id
  end

  it 'set isue_created to false in the work item' do
    participant.on_workitem
    $reply.fields['issue_created'].should_not be_nil
    $reply.fields['issue_created'].should be_false
  end

end
