require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::CheckHeaderExclusions do
  let(:participant) { Support::Participants::CheckHeaderExclusions.new }
  let(:email) do
    Mail::Message.new(
      :to         => 'support@test.com',
      :from       => 'send@test.com',
      :headers    => headers
    )
  end
  let(:workitem) do
    create_workitem({
      'email' => email.to_yaml
    })
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  context 'when there is a OOF header' do
    let(:headers) { { 'X-Auto-Response-Suppress' => "OOF" } }

    it 'will cancel the workflow when there is an auto suppress header with OOF' do
      participant.on_workitem
      $reply.fields['cancel'].should be_true
    end
  end

  context 'when there is an auto reply header' do
    let(:headers) { { 'X-Auto-Response-Suppress' => "AutoReply" } }

    it 'will cancel the workflow when there is an auto suppress header with AutoReply' do
      participant.on_workitem
      $reply.fields['cancel'].should be_true
    end
  end

  context 'when there is an OOF and auto reply header' do
    let(:headers) { { 'X-Auto-Response-Suppress' => "OOF, AutoReply" } }

    it 'will cancel the workflow when there is an auto suppress header with OOF and AutoReply' do
      participant.on_workitem
      $reply.fields['cancel'].should be_true
    end
  end

  context 'when there is no suppress header' do
    let(:headers) { {} }

    it 'will not cancel the workflow when there is no auto suppress header' do
      participant.on_workitem
      $reply.fields['cancel'].should be_nil
    end
  end

  context 'when there is a suppress header with something else' do
    let(:headers) { { 'X-Auto-Response-Suppress' => "NR" } }

    it 'will not cancel the workflow when there is no auto suppress header' do
      participant.on_workitem
      $reply.fields['cancel'].should be_nil
    end
  end

end
