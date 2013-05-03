FactoryGirl.define do
  factory :project_custom_field do
    sequence(:name) { |n| "Project custom field #{n}" }
    field_format "text"
    is_for_all true
    visible true
    editable true
  end
end
