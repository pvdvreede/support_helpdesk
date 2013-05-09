require "#{File.dirname(__FILE__)}/../spec_helper"

describe "Send email workflows", :wf => true do
  let(:engine) do
    Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
  end
  let(:support) do
    FactoryGirl.create(
      :support_helpdesk_setting
    )
  end
  let(:issue) do
    FactoryGirl.create(
      :issue,
      :support_helpdesk_setting    => support,
      :tracker                     => support.tracker,
      :project                     => support.project
    )
  end

  before do
    support
    ActionMailer::Base.deliveries = []
    @workflow = Support::Workflow.new(engine)
  end

  after do
    engine.shutdown
  end

  describe 'the ticket creation workflow' do
    before do
      @wfid = @workflow.send_created_email(issue, "test@address.com")
      engine.wait_for(@wfid)
    end

    it 'finishes properly' do
      engine.process(@wfid).should be_false
    end

    it 'sends an email to the correct address' do
      ActionMailer::Base.deliveries.count.should eq 1
      ActionMailer::Base.deliveries.first.to.should eq ["test@address.com"]
      ActionMailer::Base.deliveries.first.text_part.body.should include("ticket created")
    end

    it 'puts an attachment and journal in the issue' do
      issue.reload
      issue.attachments.count.should eq 1
      issue.journals.count.should eq 1
    end
  end

  describe 'the ticket closed workflow' do
    before do
      @wfid = @workflow.send_closing_email(issue, "test@address.com")
      engine.wait_for(@wfid)
    end

    it 'finishes properly' do
      engine.process(@wfid).should be_false
    end

    it 'sends an email to the correct address' do
      ActionMailer::Base.deliveries.count.should eq 1
      ActionMailer::Base.deliveries.first.to.should eq ["test@address.com"]
      ActionMailer::Base.deliveries.first.text_part.body.should include("ticket closed")
    end

    it 'puts an attachment and journal in the issue' do
      issue.reload
      issue.attachments.count.should eq 1
      issue.journals.count.should eq 1
    end
  end

  describe 'the user question workflow' do
    before do
      @wfid = @workflow.send_question_email(issue, "test@address.com", "Did this work?")
      engine.wait_for(@wfid)
    end

    it 'finishes properly' do
      engine.process(@wfid).should be_false
    end

    it 'sends an email to the correct address' do
      ActionMailer::Base.deliveries.count.should eq 1
      ActionMailer::Base.deliveries.first.to.should eq ["test@address.com"]
      ActionMailer::Base.deliveries.first.text_part.body.should include("user question")
    end

    it 'contains the question in the email' do
      ActionMailer::Base.deliveries.first.text_part.body.should include("Did this work?")
    end

    it 'puts an attachment and journal in the issue' do
      issue.reload
      issue.attachments.count.should eq 1
      issue.journals.count.should eq 1
    end
  end
end
