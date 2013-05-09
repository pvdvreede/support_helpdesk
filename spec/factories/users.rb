FactoryGirl.define do
  factory :user do
    sequence(:login) { |n| "login#{n}" }
    sequence(:firstname) { |n| "first#{n}" }
    sequence(:lastname) { |n| "last#{n}" }
    sequence(:mail) { |n| "email#{n}@test.com" }
    admin false
    status true
  end
end
