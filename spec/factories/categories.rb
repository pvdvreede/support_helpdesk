FactoryGirl.define do
  factory :issue_category do
    project
    sequence(:name) { |n| "Category #{n}" }
    assigned_to nil
  end
end
