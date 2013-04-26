FactoryGirl.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}"}
    is_public true
    parent_id nil
    sequence(:identifier) { |n| "ident#{n}"}
    status 1
  end
end
