require "#{File.dirname(__FILE__)}/../spec_helper"

describe "Recieve email workflow", :wf => true do
  def run_workflow(engine, email)
    workflow = Support::Workflow.new(engine)
    wfid = workflow.receive_email(email)
    engine.wait_for(wfid)
    wfid
  end

  before :all do
    DatabaseCleaner.strategy = :truncation
  end

  context "with an email sent to the user" do
    emails = Dir[File.join(email_dir, "**", "*.eml")]

    emails.each do |eml|

      describe "a new issue that sends an email with #{eml}" do

        before :all do
          DatabaseCleaner.start
          ActionMailer::Base.deliveries.clear
          @engine = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
          @email = Mail::Message.new(
            File.read(eml)
          )
          @support = FactoryGirl.create(
            :support_helpdesk_setting,
            :to_email_address           => @email.to.first,
            :active                     => true,
            :send_created_email_to_user => true
          )
          @wfid = run_workflow(@engine, @email)
        end

        after :all do
          @engine.shutdown
          DatabaseCleaner.clean_with :truncation
        end

        it 'should finish the process' do
          @engine.process(@wfid).should be_false
        end

        it 'sends an email to the user' do
          ActionMailer::Base.deliveries.count.should eq 1
          email = ActionMailer::Base.deliveries.first
          email.text_part.body.should include("ticket created")
        end

        it 'attaches the sent email to the issue with a journal item' do
          i = Issue.first
          i.attachments.count.should eq 2
          i.journals.count.should eq 2
        end
      end
    end
  end

  context "when there is no related issue" do
    emails = Dir[File.join(email_dir, "**", "*.eml")]

    emails.each do |eml|

      describe "a new issue with #{eml}" do

        before :all do
          DatabaseCleaner.start
          ActionMailer::Base.deliveries.clear
          @engine = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
          @email = Mail::Message.new(
            File.read(eml)
          )
          @support = FactoryGirl.create(
            :support_helpdesk_setting,
            :to_email_address       => @email.to.first,
            :active                 => true
          )
          @wfid = run_workflow(@engine, @email)
        end

        after :all do
          @engine.shutdown
          DatabaseCleaner.clean_with :truncation
        end

        it 'should finish the process' do
          @engine.process(@wfid).should be_false
        end

        it 'the workflow id is url encoded without any periods' do
          @wfid.include?('.').should be_false
          @wfid.include?('=').should be_false
          @wfid.include?('?').should be_false
          @wfid.include?('/').should be_false
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
          i.support_helpdesk_setting.id.should eq @support.id
        end

        it 'inserts an attachment for the issue' do
          i = Issue.first
          i.attachments.count.should eq 1
        end

        it 'inserts a journal entry that has nil notes' do
          i = Issue.first
          i.journals.count.should eq 1
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

        before :all do
          DatabaseCleaner.start
          ActionMailer::Base.deliveries.clear
          @engine = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
          @email = Mail::Message.new(
            File.read(eml)
          )
          @support = FactoryGirl.create(
            :support_helpdesk_setting,
            :to_email_address       => @email.to.first,
            :active                 => true
          )
          @current_issue = FactoryGirl.create(
            :issue,
            :support_helpdesk_setting => @support,
            :tracker                  => @support.tracker,
            :project                  => @support.project
          )
          @email.subject = "For Ticket ##{@current_issue.id.to_s}: This is the subject"
          @wfid = run_workflow(@engine, @email)
        end

        after :all do
          @engine.shutdown
          DatabaseCleaner.clean_with :truncation
        end

        it 'should finish the process' do
          @engine.process(@wfid).should be_false
        end

        it 'will add a journal note' do
          @current_issue.journals.count.should eq 1
        end

        it 'will add an attachment' do
          @current_issue.attachments.count.should eq 1
        end

        it 'will create a message id' do
          @current_issue.issues_support_message_ids.count.should eq 1
        end

      end
    end
  end

  context "when there is a related issue via in-reply-to header" do
    emails = Dir[File.join(email_dir, "**", "*.eml")]

    emails.each do |eml|

      describe "a updated issue with #{eml}" do

        before :all do
          DatabaseCleaner.start
          ActionMailer::Base.deliveries.clear
          @engine = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
          @email  = Mail::Message.new(
            File.read(eml)
          )
          @support = FactoryGirl.create(
            :support_helpdesk_setting,
            :to_email_address       => @email.to.first,
            :active                 => true
          )
          @current_issue = FactoryGirl.create(
            :issue,
            :support_helpdesk_setting => @support,
            :tracker                  => @support.tracker,
            :project                  => @support.project
          )
          @message_id = FactoryGirl.create(
            :issues_support_message_id,
            :issue                    => @current_issue,
            :support_helpdesk_setting => @support,
            :message_id               => 'thisisthefirstemailid@test.com'
          )
          @email.subject = "A random subject that has changed"
          @email.in_reply_to = '<thisisthefirstemailid@test.com>'
          @wfid = run_workflow(@engine, @email)
        end

        after :all do
          @engine.shutdown
          DatabaseCleaner.clean_with :truncation
        end

        it 'should finish the process' do
          @engine.process(@wfid).should be_false
        end

        it 'will not create a new issue' do
          Issue.count.should eq 1
        end

        it 'will add a journal note' do
          @current_issue.journals.count.should eq 1
        end

        it 'will add an attachment' do
          @current_issue.attachments.count.should eq 1
        end

        it 'will create a message id' do
          @current_issue.issues_support_message_ids.count.should eq 2
        end
      end
    end
  end

  context "when the email has a suppression header" do
  end

  context "when there is no active supports" do
    eml = File.join(email_dir, "multi_basic.eml")

    before :all do
      @engine = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
      ActionMailer::Base.deliveries.clear
      @email = Mail::Message.new(
        File.read(eml)
      )
      @support = FactoryGirl.create(
        :support_helpdesk_setting,
        :to_email_address       => @email.to.first,
        :active                 => false
      )
      run_workflow(@engine, @email)
    end

    after :all do
      @engine.shutdown
    end

    it 'should finish the process' do
      @engine.process(@wfid).should be_false
    end

    it 'will not insert any issues' do
      Issue.all.should be_empty
    end

    it 'will not send any emails' do
      ActionMailer::Base.deliveries.should be_empty
    end
  end
end
