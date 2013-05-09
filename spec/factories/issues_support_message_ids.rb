FactoryGirl.define do
  factory :issues_support_message_id do
    issue
    sequence(:message_id) { |n| "message#{n}@testserver.com" }
    support_helpdesk_setting
  end
end
