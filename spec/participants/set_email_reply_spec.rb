require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::SetEmailReply do
  let(:participant) { Support::Participants::SetEmailReply.new }
  let(:support)     { FactoryGirl.create(:support_helpdesk_setting, :to_email_address => 'support@test.com') }
  let(:email) do
    Mail::Message.new(
      :to           => ['support@test.com', "another@email.com"],
      :from         => 'send@test.com',
      :message_id   => 'themessage@id.com'
    )
  end
  let(:workitem) do
    create_workitem({
      'email'            => email.to_yaml,
      'support_settings' => support.attributes
    })
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  it 'set the email_reply_to field in the work item' do
    participant.on_workitem
    $reply.fields['email_reply_to'].should_not be_nil
  end

  it 'sets the field with the from and to of the email without support email' do
    participant.on_workitem
    $reply.fields['email_reply_to'].should eq "send@test.com; another@email.com"
  end

end
