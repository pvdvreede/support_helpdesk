require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::SearchCurrentIssue do
  let(:participant) { Support::Participants::SearchCurrentIssue.new }
  let(:issue) do
    FactoryGirl.create(
      :issue,
      :support_helpdesk_setting => support,
      :tracker                  => support.tracker,
      :project                  => support.project
    )
  end
  let(:support) do
    FactoryGirl.create(
      :support_helpdesk_setting
    )
  end
  let(:workitem) do
    create_workitem({
      'email' => email.to_yaml,
      'email_subject' => subject
    })
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  context 'when there is no related issue' do
    let(:email)  { Mail::Message.new(:subject => "new issue", :message_id => "not@exist") }
    let(:subject){ "new issue" }

    it 'will not set the related_issue field' do
      participant.on_workitem
      $reply.fields['related_issue'].should be_nil
    end
  end

  context 'when there is a related issue in the subject line' do
    let(:email) { Mail::Message.new(:subject => "Ticket ##{issue.id.to_s}: A current issue", :message_id => "not@exist") }
    let(:subject) { "Ticket ##{issue.id.to_s}: A current issue" }

    it 'will set the related_issue field with the issue' do
      participant.on_workitem
      $reply.fields['related_issue'].should eq issue.attributes
    end

    context 'when the related issue is closed' do
      let(:issue) do
        FactoryGirl.create(
          :closed_issue,
          :support_helpdesk_setting => support,
          :tracker                  => support.tracker,
          :project                  => support.project
        )
      end

      it 'will have an empty related_issue field' do
        participant.on_workitem
        $reply.fields['related_issue'].should be_nil
      end
    end
  end

  context 'when there is a related issue in the reply_to' do
    let(:issue_message_id) { FactoryGirl.create(:issues_support_message_id, :issue => issue, :message_id => "heyim@here", :support_helpdesk_setting => support) }
    let(:email) { Mail::Message.new(:subject => "current issue but new subject", :message_id => "not@exist", :in_reply_to => "heyim@here") }
    let(:subject) { "current issue but new subject" }

    it 'will set the related_issue field with the issue' do
      issue_message_id
      participant.on_workitem
      $reply.fields['related_issue'].should eq issue.attributes
    end

    context 'when the related issue is closed' do
      let(:issue) do
        FactoryGirl.create(
          :closed_issue,
          :support_helpdesk_setting => support,
          :tracker                  => support.tracker,
          :project                  => support.project
        )
      end

      it 'will have an empty related_issue field' do
        participant.on_workitem
        $reply.fields['related_issue'].should be_nil
      end
    end
  end

  context 'when there is a related issue in the references' do
    let(:issue_message_id) { FactoryGirl.create(:issues_support_message_id, :issue => issue, :message_id => "heyim@here", :support_helpdesk_setting => support) }
    let(:email) { Mail::Message.new(:subject => "current issue but new subject", :message_id => "not@exist", :references => "heyim@here") }
    let(:subject) { "current issue but new subject" }

    it 'will set the related_issue field with the issue' do
      issue_message_id
      participant.on_workitem
      $reply.fields['related_issue'].should eq issue.attributes
    end

    context 'when the related issue is closed' do
      let(:issue) do
        FactoryGirl.create(
          :closed_issue,
          :support_helpdesk_setting => support,
          :tracker                  => support.tracker,
          :project                  => support.project
        )
      end

      it 'will have an empty related_issue field' do
        participant.on_workitem
        $reply.fields['related_issue'].should be_nil
      end
    end
  end

end
