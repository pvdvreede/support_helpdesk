FactoryGirl.define do
  factory :group do
    sequence(:lastname) { |n| "last#{n}"}
  end
end
