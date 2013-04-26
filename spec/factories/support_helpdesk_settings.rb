FactoryGirl.define  do
  factory :support_helpdesk_setting do
    sequence(:name) { |n| "Support setup #{n}" }
    project
    author { FactoryGirl.create :user }
    sequence(:to_email_address) { |n| "to#{n}@email.com"}
    sequence(:from_email_address) { |n| "from#{n}@email.com"}
    tracker
    reply_email_custom_field { FactoryGirl.create :issue_custom_field }
    type_custom_field { FactoryGirl.create :issue_custom_field }
    assignee_group { FactoryGirl.create :group }
    created_template_name "test"
    closed_template_name "test"
    question_template_name "test"
    send_created_email_to_user false
    send_closed_email_to_user false
    last_assigned_user { FactoryGirl.create :user }
    new_status { FactoryGirl.create :issue_status }
    priority { FactoryGirl.create :issue_priority }
    search_in_to true
    search_in_cc true
    active true
  end
end
