FactoryGirl.define do
  factory :issue do
    tracker
    project   { FactoryGirl.create(:project, :trackers => [tracker]) }
    sequence(:subject)     { |n| "Subject #{n}" }
    sequence(:description) { |n| "description #{n}" }
    category  { FactoryGirl.create(:issue_category) }
    status    { FactoryGirl.create(:issue_status) }
    assigned_to { FactoryGirl.create(:user) }
    author    { FactoryGirl.create(:user) }
    priority  { FactoryGirl.create(:issue_priority) }

    factory :closed_issue do
      status { FactoryGirl.create(:issue_status, :is_closed => true)}
    end
  end
end
