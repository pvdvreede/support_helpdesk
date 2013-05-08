require "#{File.dirname(__FILE__)}/../spec_helper"

describe Support::Participants::SearchProject do
  let(:participant)  { Support::Participants::SearchProject.new }
  let(:email)        { Mail::Message.new(:to => 'support@test.com', :from => 'send@mycompany.com') }
  let(:project)      { FactoryGirl.create(:project) }
  let(:project_mail) { FactoryGirl.create(:project_custom_field) }
  let(:support)      { FactoryGirl.build(:support_helpdesk_setting, :email_domain_custom_field => project_mail) }
  let(:workitem) do
    create_workitem({
      'email'            => email.to_yaml,
      'support_settings' => support.attributes
    })
  end

  before do
    participant.extend Support::Spec::Reply
    $reply = nil
    participant.workitem = workitem
  end

  context 'when the domain name is set for a project' do
    before do
      FactoryGirl.create(
        :custom_value,
        :custom_field => project_mail,
        :customized_id => project.id,
        :customized_type => "Project",
        :value => "mycompany.com"
      )
    end

    it 'sets the related_project field with the correct project' do
      participant.on_workitem
      $reply.fields['related_project']['id'].should eq project.id
    end
  end

  context 'when the domain name is not set for a project' do
    it 'sets the default project in the support settings' do
      participant.on_workitem
      $reply.fields['related_project']['id'].should eq support.project_id
    end
  end

  context 'when the domain name does not match for a project' do
    before do
      FactoryGirl.create(
        :custom_value,
        :custom_field => project_mail,
        :customized_id => project.id,
        :customized_type => "Project",
        :value => "notmycompany.com"
      )
    end

    it 'sets the default project in the support settings' do
      participant.on_workitem
      $reply.fields['related_project']['id'].should eq support.project_id
    end
  end

  context 'when the custom field is not set for the support object' do
    let(:support)  do
      FactoryGirl.build(
        :support_helpdesk_setting,
        :email_domain_custom_field => nil
      )
    end

    it 'sets the default project in the support settings' do
      participant.on_workitem
      $reply.fields['related_project']['id'].should eq support.project_id
    end
  end

end
