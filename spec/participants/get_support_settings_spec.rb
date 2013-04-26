require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::GetSupportSettings do
  let(:participant) { Support::Participants::GetSupportSettings.new }
  let(:email)       { Mail::Message.new }
  let(:workitem)    { create_workitem({ 'email' => email.to_yaml }) }

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  context 'has support email as to' do
    let(:email)     { Mail::Message.new(:to => 'support@test.com') }

    it 'has support setting disabled' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :active => false
      )
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end

    it 'has support setting with cc only' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :search_in_to => false,
        :search_in_cc => true
      )
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end

    it 'has support setting with to only' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :search_in_to => true,
        :search_in_cc => false
      )
      participant.on_workitem
      $reply.fields['support_settings'].should_not be_nil
      $reply.fields['support_settings']['name'].should eq support.name
    end


    it 'has support setting with both' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :search_in_to => true,
        :search_in_cc => true
      )
      participant.on_workitem
      $reply.fields['support_settings'].should_not be_nil
      $reply.fields['support_settings']['name'].should eq support.name
    end
  end

  context 'has support email as cc' do
    let(:email)     { Mail::Message.new(:cc => 'support@test.com') }

    it 'has support setting disabled' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :active => false
      )
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end

    it 'has support setting with to only' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :search_in_to => true,
        :search_in_cc => false
      )
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end

    it 'has support setting with cc only' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :search_in_to => false,
        :search_in_cc => true
      )
      participant.on_workitem
      $reply.fields['support_settings'].should_not be_nil
      $reply.fields['support_settings']['name'].should eq support.name
    end


    it 'has support setting with both' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :search_in_to => true,
        :search_in_cc => true
      )
      participant.on_workitem
      $reply.fields['support_settings'].should_not be_nil
      $reply.fields['support_settings']['name'].should eq support.name
    end
  end

  context 'does not have support email' do
    let(:email)     { Mail::Message.new(:cc => 'nosupport@test.com') }

    it 'has support setting disabled' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :active => false
      )
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end

    it 'has support setting with to only' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :search_in_to => true,
        :search_in_cc => false
      )
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end

    it 'has support setting with cc only' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :search_in_to => false,
        :search_in_cc => true
      )
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end


    it 'has support setting with both' do
      support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address => "support@test.com",
        :search_in_to => true,
        :search_in_cc => true
      )
      participant.on_workitem
      $reply.fields['cancel'].should_not be_nil
      $reply.fields['cancel'].should be_true
    end
  end

end
