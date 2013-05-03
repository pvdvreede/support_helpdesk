FactoryGirl.define do
  factory :custom_value do
    sequence(:value) { |n| "custom value #{n}" }
  end
end
