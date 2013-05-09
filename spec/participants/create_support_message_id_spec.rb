require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::CreateSupportMessageId do
  let(:participant) { Support::Participants::CreateSupportMessageId.new }
  let(:support)     { FactoryGirl.create(:support_helpdesk_setting) }
  let(:issue)       { FactoryGirl.create(:issue) }
  let(:email) do
    Mail::Message.new(
      :to           => 'support@test.com',
      :from         => 'send@test.com',
      :message_id   => 'themessage@id.com'
    )
  end
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

  context 'for a new issue' do
    let(:issue_created) { true }

    it 'creates an email message id in the table for the issue' do
      IssuesSupportMessageId.where(:issue_id => issue.id).count.should eq 0
      participant.on_workitem
      IssuesSupportMessageId.where(:issue_id => issue.id).count.should eq 1
    end

    it 'has a link to the support item' do
      participant.on_workitem
      m = IssuesSupportMessageId.where(:issue_id => issue.id).first
      m.support_helpdesk_setting_id.should eq support.id
    end

    it 'contains the correct email message_id' do
      participant.on_workitem
      m = IssuesSupportMessageId.where(:issue_id => issue.id).first
      m.message_id.should eq email.message_id
      m.parent_id.should be_nil
    end

  end

  context 'for an updated issue' do
    let(:issue_created) { false }

    before do
      @parent = FactoryGirl.create(
        :issues_support_message_id,
        :issue_id                         => issue.id,
        :support_helpdesk_setting_id      => support.id,
        :message_id                       => 'relatedmessage@id.com',
        :parent_id                        => nil
      )
    end

    it 'creates an email message id in the table for the issue' do
      IssuesSupportMessageId.where(:issue_id => issue.id).count.should eq 1
      participant.on_workitem
      IssuesSupportMessageId.where(:issue_id => issue.id).count.should eq 2
    end

    it 'has a link to the support item' do
      participant.on_workitem
      m = IssuesSupportMessageId.where(:issue_id => issue.id).first
      m.support_helpdesk_setting_id.should eq support.id
    end

    it 'has a link to the parent message id' do
      participant.on_workitem
      m = IssuesSupportMessageId.where(
        :issue_id     => issue.id,
        :parent_id    => @parent.id,
        :message_id   => email.message_id
      ).first
      m.should_not be_nil
    end

  end

end
