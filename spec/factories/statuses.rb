FactoryGirl.define do
  factory :issue_status do
    sequence(:name) { |n| "Status #{n}" }
    is_closed false
    is_default false
    sequence(:position) { |n| n + 1 }
  end
end
