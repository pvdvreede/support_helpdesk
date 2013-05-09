require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::UpdateProcessTime do
  let(:participant) { Support::Participants::UpdateProcessTime.new }
  let(:support)     { FactoryGirl.create(:support_helpdesk_setting) }
  let(:workitem) do
    create_workitem({
      'support_settings' => support.attributes
    })
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  it 'update the last process time on the related support item' do
    support.last_processed.should be_nil
    participant.on_workitem
    support.reload
    support.last_processed.should_not be_nil
  end

  it 'updates the last process time with the current time' do
    before = Time.now
    participant.on_workitem
    after = Time.now
    support.reload
    support.last_processed.should > before
    support.last_processed.should < after
  end

end
