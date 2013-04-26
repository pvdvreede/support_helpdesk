FactoryGirl.define do
  factory :tracker do
    sequence(:name) { |n| "Tracker #{n}"}
    sequence(:position) { |n| n + 1 }
  end
end
