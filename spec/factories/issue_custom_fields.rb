FactoryGirl.define do
  factory :issue_custom_field do
    sequence(:name) { |n| "Issue custom field #{n}" }
    field_format "text"
    is_for_all true
    visible true
    editable true
  end
end
