FactoryGirl.define do
  factory :issue_priority do
    sequence(:name) { |n| "Priority #{n}"}
  end
end
