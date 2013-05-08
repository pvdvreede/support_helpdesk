require "#{File.dirname(__FILE__)}/../spec_helper"

describe "Participant registration" do
  let(:workflow) { Support::Workflow.new(RuoteKit.engine) }

  it 'will register all participants' do
    file_count = Dir[File.join(file_root, "lib", "support", "participants", "*.rb")].count - 1
    workflow.participants.count.should eq file_count
  end

  it 'contain constants for the participant classes' do
    workflow.participants.should include(Support::Participants::GetGlobalSettings)
  end

  it 'will not contain the base class' do
    workflow.participants.should_not include(Support::Participants::BaseParticipant)
  end
end
