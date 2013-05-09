require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::SetEmailReply do
  let(:participant) { Support::Participants::SetEmailReply.new }
  let(:support)     { FactoryGirl.create(:support_helpdesk_setting, :to_email_address => 'support@test.com') }
  let(:email) do
    Mail::Message.new(
      :to           => ['support@test.com', "another@email.com"],
      :cc           => 'thecc@test.com',
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

  context 'when reply to all is true' do
    let(:support) do
      FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address           => 'support@test.com',
        :reply_all_for_outgoing     => true
      )
    end

    it 'set the email_reply_to field in the work item with all email addresses' do
      participant.on_workitem
      $reply.fields['email_reply_to'].should eq "send@test.com; another@email.com; thecc@test.com"
    end
  end


  context 'when reply to all is false' do
    let(:support) do
      FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address           => 'support@test.com',
        :reply_all_for_outgoing     => false
      )
    end

    it 'sets the email reply field with the from only' do
      participant.on_workitem
      $reply.fields['email_reply_to'].should eq "send@test.com"
    end

  end

end
