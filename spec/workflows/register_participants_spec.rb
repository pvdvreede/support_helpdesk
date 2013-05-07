require "#{File.dirname(__FILE__)}/../spec_helper"

describe "Participant registration" do
  let(:workflow) { Support::Workflow.new(RuoteKit.engine) }

  it 'will register all participants' do
    workflow.participants.count.should eq 11
  end

  it 'contain constants for the participant classes' do
    workflow.participants.should include(Support::Participants::GetGlobalSettings)
  end

  it 'will not contain the base class' do
    workflow.participants.should_not include(Support::Participants::BaseParticipant)
  end
end
