FactoryGirl.define do
  factory :journal do
    sequence(:notes) { |n| "Journal notes #{n}"}
    user
    journalized      { FactoryGirl.create(:issue) }
  end
end
