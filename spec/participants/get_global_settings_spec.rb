require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::GetGlobalSettings do
  let(:participant) { Support::Participants::GetGlobalSettings.new }
  let(:email)       { Mail::Message.new }
  let(:workitem)    { create_workitem({ 'email' => email.to_yaml }) }

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  it 'retrieves global settings and sets workitem field' do
    $reply.should be_nil
    participant.on_workitem
    $reply.fields['global_settings'].should_not be_nil
    $reply.fields['global_settings'].should eq Setting.plugin_support_helpdesk
  end


end
