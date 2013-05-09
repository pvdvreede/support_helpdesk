require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::CreateIssueBody do
  let(:participant) { Support::Participants::CreateIssueBody.new }
  let(:plain_basic_email) do
    Mail::Message.new(File.read(File.join(email_dir, "plain_basic.eml")))
  end
  let(:multi_basic_email) do
    Mail::Message.new(File.read(File.join(email_dir, "multi_basic.eml")))
  end
  let(:html_basic_email) do
    Mail::Message.new(File.read(File.join(email_dir, "html_basic.eml")))
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  context 'when there is plain text only' do
    let(:workitem) do
      create_workitem({
        'email' => plain_basic_email.to_yaml
      })
    end

    it 'will set the body as plain text' do
      participant.on_workitem
      $reply.fields['email_body'].should eq "Plain email.\n\nHope it works well!\n\nMikel"
    end
  end

  context 'when there is html only' do
    let(:workitem) do
      create_workitem({
        'email' => html_basic_email.to_yaml
      })
    end

    it 'will set the body to say it cannot render the body' do
      participant.on_workitem
      $reply.fields['email_body'].should eq "Cannot add body, please open attached email file."
    end

  end

  context 'when there is multipart' do
    let(:workitem) do
      create_workitem({
        'email' => multi_basic_email.to_yaml
      })
    end

    it 'will set the body as the plain text body' do
      participant.on_workitem
      $reply.fields['email_body'].should eq "This is a test *multi part* email.\n\nRegards,\n\nPaul."
    end
  end

  context 'when the email has Chinese characters' do

  end

end
