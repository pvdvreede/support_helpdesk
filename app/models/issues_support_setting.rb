class IssuesSupportSetting < ActiveRecord::Base
  unloadable
  
  # TODO make sure these are deleted when an issue is deleted
  belongs_to :issue
  belongs_to :support_helpdesk_setting
end
