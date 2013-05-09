require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::SendEmail do
  let(:participant) { Support::Participants::SendEmail.new }
  let(:email)       { Mail::Message.new(:to => 'support@test.com', :from => 'send@test.com') }
  let(:template)    { "ticket_created" }
  let(:issue) do
    FactoryGirl.create(
      :issue,
      :support_helpdesk_setting   => support,
      :tracker                    => support.tracker,
      :project                    => support.project
    )
  end
  let(:support)     { FactoryGirl.create(:support_helpdesk_setting) }
  let(:workitem) do
    create_workitem({
      'related_issue'     => issue.attributes,
      'outgoing_email_to' => 'paul@doesntreallyexist.com',
      'params'            => {
        'template'        => template
      }
    })
  end

  before do
    ActionMailer::Base.deliveries = []
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  it 'sends an email' do
    participant.on_workitem
    ActionMailer::Base.deliveries.count.should eq 1
  end

  context "with to address as param" do
    let(:workitem) do
      create_workitem({
        'related_issue'     => issue.attributes,
        'params'            => {
          'outgoing_email_to' => 'paul@doesntreallyexist.com',
          'template'          => template
        }
      })
    end

    it 'is to paul@doesntreallyexist.com' do
      participant.on_workitem
      email = ActionMailer::Base.deliveries.first
      email.to.first.should eq "paul@doesntreallyexist.com"
    end
  end

  it 'is to paul@doesntreallyexist.com' do
    participant.on_workitem
    email = ActionMailer::Base.deliveries.first
    email.to.first.should eq "paul@doesntreallyexist.com"
  end

  it 'attaches the outgoing email to the work item' do
    participant.on_workitem
    $reply.fields['outgoing_email'].should_not be_nil
  end

  context "sending a ticket creation email without opts" do
    let(:template)    { "ticket_created" }

    it 'uses the ticket creation mailer template' do
      participant.on_workitem
      email = ActionMailer::Base.deliveries.first
      email.text_part.body.should include("ticket created")
    end
  end

  context "sending a ticket closed email without opts" do
    let(:template)    { "ticket_closed" }

    it 'uses the ticket creation mailer template' do
      participant.on_workitem
      email = ActionMailer::Base.deliveries.first
      email.text_part.body.should include("ticket closed")
    end
  end

  context "sending a user question email with opts" do
    let(:template)    { "user_question" }
    let(:workitem) do
      create_workitem({
        'related_issue'       => issue.attributes,
        'outgoing_email_to'   => 'paul@doesntreallyexist.com',
        'outgoing_email_opts' => { :question => "Howdy doody" },
        'params'              => {
            'template'        => template
          }
      })
    end

    it 'uses the user question mailer template' do
      participant.on_workitem
      email = ActionMailer::Base.deliveries.first
      email.text_part.body.should include("user question")
    end

    it 'has the question in the email' do
      participant.on_workitem
      email = ActionMailer::Base.deliveries.first
      email.text_part.body.should include("Howdy doody")
    end
  end

end
