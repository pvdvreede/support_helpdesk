require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::AddEmailAttachment do
  let(:participant)  { Support::Participants::AddEmailAttachment.new }
  let(:email)        { Mail::Message.new(:to => 'support@test.com', :from => 'send@mycompany.com', :message_id => 'testingtesting') }
  let(:issue) do
    FactoryGirl.create(
      :issue,
      :support_helpdesk_setting => support,
      :tracker                  => support.tracker,
      :project                  => support.project
    )
  end
  let(:support)      { FactoryGirl.create(:support_helpdesk_setting) }
  let(:workitem) do
    create_workitem({
      'email'            => email.to_yaml,
      'support_settings' => support.attributes,
      'related_issue'    => issue.attributes,
      'issue_created'    => issue_created
    })
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  context 'newly created issue' do
    let(:issue_created)   { true }

    it 'will put the email in an attachment' do
      issue.attachments.should be_empty
      participant.on_workitem
      issue.attachments.count.should eq 1
    end

    it 'will create a description for the attachment' do
      participant.on_workitem
      issue.attachments.first.description.should eq "Original email sent from Customer."
    end

    it 'will set the filename with from email and current time' do
      participant.on_workitem
      issue.attachments.first.filename.should =~ /^#{email.from.first.downcase}_[0-9]+{14}_[a-z0-9]{6}\.eml$/
    end

    it 'will add the attachment details to the context' do
      participant.on_workitem
      $reply.fields['related_attachment'].should_not be_nil
    end

    it 'will append a related journal to the context' do
      participant.on_workitem
      $reply.fields['related_journal'].should_not be_nil
    end

  end

  context 'already present issue' do
    let(:workitem) do
      create_workitem({
        'email'            => email.to_yaml,
        'support_settings' => support.attributes,
        'related_issue'    => issue.attributes,
        'issue_created'    => issue_created,
        'related_journal'  => journal.attributes
      })
    end
    let(:issue_created)   { false }
    let(:journal) do
      FactoryGirl.create(
        :journal,
        :journalized => issue,
        :user_id     => support.author_id
      )
    end

    it 'will put the email in an attachment' do
      issue.attachments.should be_empty
      participant.on_workitem
      issue.attachments.count.should eq 1
    end

    it 'will create a description for the attachment' do
      participant.on_workitem
      issue.reload
      issue.attachments.first.description.should eq "Supplemental email received from #{email.from.first.downcase}."
    end

    it 'will set the filename with from email and current time' do
      participant.on_workitem
      issue.reload
      issue.attachments.first.filename.should =~ /^#{email.from.first.downcase}_[0-9]+_[a-z0-9]{6}\.eml$/
    end

    it 'will create a attachment link in the journal entry' do
      query = JournalDetail.where(
        :journal_id     => journal.id,
        :property       => 'attachment'
      )
      query.should be_empty
      participant.on_workitem
      query.count.should eq 1
      query.first.value.should =~ /^#{email.from.first.downcase}_[0-9]+_[a-z0-9]{6}\.eml$/
    end

    it 'will add the attachment details to the context' do
      participant.on_workitem
      $reply.fields['related_attachment'].should_not be_nil
    end

  end

end
