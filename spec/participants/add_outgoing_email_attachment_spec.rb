require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::AddOutgoingEmailAttachment do
  let(:participant)  { Support::Participants::AddOutgoingEmailAttachment.new }
  let(:email)        { Mail::Message.new(:to => 'support@test.com', :from => 'send@mycompany.com', :message_id => 'testingtesting') }
  let(:issue) do
    FactoryGirl.create(
      :issue,
      :support_helpdesk_setting => support,
      :tracker                  => support.tracker,
      :project                  => support.project
    )
  end
  let(:support)      { FactoryGirl.create(:support_helpdesk_setting) }
  let(:workitem) do
    create_workitem({
      'outgoing_email'   => email.to_yaml,
      'support_settings' => support.attributes,
      'related_issue'    => issue.attributes
    })
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  it 'will put the email in an attachment' do
    issue.attachments.should be_empty
    participant.on_workitem
    issue.attachments.count.should eq 1
  end

  it 'will create a description for the attachment' do
    participant.on_workitem
    issue.attachments.first.description.should include("Email sent by us to")
  end

  it 'will put the description in the journal note' do
    participant.on_workitem
    issue.journals.first.notes.should include("Email sent by us to")
  end

  it 'will set the filename with from email and current time' do
    participant.on_workitem
    issue.attachments.first.filename.should =~ /^#{email.from.first.downcase}_[0-9]{14}_[a-z0-9]{6}\.eml$/
  end

  it 'will add the attachment details to the context' do
    participant.on_workitem
    $reply.fields['outgoing_email_attachment'].should_not be_nil
  end

end
