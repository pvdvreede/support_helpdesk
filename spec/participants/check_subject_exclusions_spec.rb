require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::CheckSubjectExclusions do
  let(:participant) { Support::Participants::CheckSubjectExclusions.new }
  let(:workitem)    { create_workitem({
                        'email' => email.to_yaml,
                        'support_settings' => support
                      }) }

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  context 'when there is no subject exclusion list' do
    let(:support) { FactoryGirl.attributes_for(
        :support_helpdesk_setting,
        :to_email_address => 'support@test.com'
      ).stringify_keys }
    let(:email)   { Mail::Message.new(:to => 'support@test.com', :subject => 'a standard subject') }

    it 'should not cancel the workflow' do
      participant.on_workitem
      $reply.fields['cancel'].should be_nil
    end
  end

  context 'when there is no subject in the email' do
    let(:support) { FactoryGirl.attributes_for(
        :support_helpdesk_setting,
        :to_email_address => 'support@test.com'
      ).stringify_keys }
    let(:email)   { Mail::Message.new(:to => 'support@test.com') }

    it 'should continue the workflow and set a subject' do
      participant.on_workitem
      $reply.fields['cancel'].should be_nil
      $reply.fields['email_subject'].should_not be_nil
      $reply.fields['email_subject'].should eq '(no subject)'
    end
  end

  context 'when the email is part of excluded subject list' do
    let(:support) { FactoryGirl.attributes_for(
        :support_helpdesk_setting,
        :to_email_address => 'support@test.com',
        :subject_exclusion_list => '^banned,banned$'
      ).stringify_keys }
    let(:email)   { Mail::Message.new(:to => 'support@test.com', :subject => 'banned is the first word here') }

    it 'should cancel the workflow' do
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end
  end

  context 'when there is an exclusion list that subject is NOT apart of' do
    let(:support) { FactoryGirl.attributes_for(
        :support_helpdesk_setting,
        :to_email_address => 'support@test.com',
        :subject_exclusion_list => '^banned,banned$'
      ).stringify_keys }
    let(:email)   { Mail::Message.new(:to => 'support@test.com', :subject => 'this is not banned for sure') }

    it 'should continue the workflow' do
      participant.on_workitem
      $reply.fields['cancel'].should be_nil
      $reply.fields['email_subject'].should_not be_nil
      $reply.fields['email_subject'].should eq 'this is not banned for sure'
    end
  end

end
