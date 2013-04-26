require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::CheckFromExclusions do
  let(:participant) { Support::Participants::CheckFromExclusions.new }
  let(:email)       { Mail::Message.new(:to => 'support@test.com', :from => 'send@test.com') }
  let(:workitem)    { create_workitem({
                        'email' => email.to_yaml,
                        'support_settings' => support
                      }) }

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  context 'when there is no exclusion list' do
    let(:support) { FactoryGirl.attributes_for(
        :support_helpdesk_setting,
        :to_email_address => 'support@test.com'
      ).stringify_keys }

    it 'should not cancel the workflow' do
      participant.on_workitem
      $reply.fields['cancel'].should be_nil
    end
  end

  context 'when there is no from in the email' do
    let(:support) { FactoryGirl.attributes_for(
        :support_helpdesk_setting,
        :to_email_address => 'support@test.com'
      ).stringify_keys }
    let(:email)   { Mail::Message.new(:to => 'support@test.com') }

    it 'should cancel the workflow' do
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end
  end

  context 'when there is an exclusion list that from is apart of' do
    let(:support) { FactoryGirl.attributes_for(
        :support_helpdesk_setting,
        :to_email_address => 'support@test.com',
        :domains_to_ignore => 'test.com$,^hi@hello.com$'
      ).stringify_keys }

    it 'should cancel the workflow' do
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end
  end

  context 'when there is an exclusion list that from is NOT apart of' do
    let(:support) { FactoryGirl.attributes_for(
        :support_helpdesk_setting,
        :to_email_address => 'support@test.com',
        :domains_to_ignore => 'test123.com$,^hi@hello.com$'
      ).stringify_keys }

    it 'should continue the workflow' do
      participant.on_workitem
      $reply.fields['cancel'].should be_nil
    end
  end

end
