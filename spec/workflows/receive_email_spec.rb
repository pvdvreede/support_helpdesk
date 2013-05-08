require "#{File.dirname(__FILE__)}/../spec_helper"

describe "Recieve email workflow", :wf => true do
  let(:engine) do
    Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
  end

  context "when there is no related issue" do

    emails = Dir[File.join(email_dir, "**", "*.eml")]

    emails.each do |eml|

      describe "a new issue with #{eml}" do
        let(:support) do
          FactoryGirl.create(
            :support_helpdesk_setting,
            :to_email_address       => email.to.first,
            :active                 => true
          )
        end
        let(:email) do
          Mail::Message.new(
            File.read(eml)
          )
        end

        before do
          support
          ActionMailer::Base.deliveries = []
          @workflow = Support::Workflow.new(engine)
          @wfid = @workflow.receive_email(email)
          engine.wait_for(@wfid)
        end

        after do
          engine.shutdown
        end

        context "with an email sent to the user" do
          let(:support) do
            FactoryGirl.create(
              :support_helpdesk_setting,
              :to_email_address           => email.to.first,
              :active                     => true,
              :send_created_email_to_user => true
            )
          end

          it 'should finish the process' do
            engine.process(@wfid).should be_false
          end

          it 'sends an email to the user' do
            ActionMailer::Base.deliveries.count.should eq 1
            email = ActionMailer::Base.deliveries.first
            email.text_part.body.should include("ticket created")
          end
        end

        it 'should finish the process' do
          engine.process(@wfid).should be_false
        end

        it 'provides the correct wf id' do
          @wfid.should eq email.message_id
        end

        it 'inserts an issue' do
          i = Issue.first
          i.should_not be_nil
        end

        it 'does not send an email to the user' do
          ActionMailer::Base.deliveries.should be_empty
        end

        it 'relates the issue to the correct support item' do
          i = Issue.first
          i.support_helpdesk_setting.id.should eq support.id
        end

        it 'inserts an attachment for the issue' do
          i = Issue.first
          i.attachments.should_not be_empty
        end

        it 'inserts a journal entry that has nil notes' do
          i = Issue.first
          i.journals.first.should_not be_nil
          i.journals.first.notes.should be_nil
        end

        it 'will create a message id' do
          i = Issue.first
          i.issues_support_message_ids.count.should eq 1
        end

      end

    end

  end

  context "when there is a related issue via subject line" do

    emails = Dir[File.join(email_dir, "**", "*.eml")]

    emails.each do |eml|

      describe "a updated issue with #{eml}" do
        let(:support) do
          FactoryGirl.create(
            :support_helpdesk_setting,
            :to_email_address       => email.to.first,
            :active                 => true
          )
        end
        let(:email) do
          Mail::Message.new(
            File.read(eml)
          )
        end
        let(:current_issue) do
          FactoryGirl.create(
            :issue,
            :support_helpdesk_setting => support,
            :tracker                  => support.tracker,
            :project                  => support.project
          )
        end

        before do
          support
          email.subject = "For Ticket ##{current_issue.id.to_s}: This is the subject"
          @workflow = Support::Workflow.new(engine)
          @wfid = @workflow.receive_email(email)
          engine.wait_for(@wfid)
        end

        after do
          engine.shutdown
        end

        it 'should finish the process' do
          engine.process(@wfid).should be_false
        end

        it 'will add a journal note' do
          current_issue.journals.count.should eq 1
        end

        it 'will add an attachment' do
          current_issue.attachments.count.should eq 1
        end

        it 'will create a message id' do
          current_issue.issues_support_message_ids.count.should eq 1
        end

      end
    end
  end

  context "when there is no active supports" do
    eml = File.join(email_dir, "multi_basic.eml")

    let(:support) do
      FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address       => email.to.first,
        :active                 => false
      )
    end
    let(:email) do
      Mail::Message.new(
        File.read(eml)
      )
    end

    before do
      support
      @workflow = Support::Workflow.new(engine)
      @wfid = @workflow.receive_email(email)
      engine.wait_for(@wfid)
    end

    after do
      engine.shutdown
    end

    it 'should finish the process' do
      engine.process(@wfid).should be_false
    end

    it 'will not insert any issues' do
      Issue.all.should be_empty
    end

  end
end
