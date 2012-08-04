class IssuesSupportSetting < ActiveRecord::Base
  unloadable
  
  belongs_to :issue
  belongs_to :support_helpdesk_setting
end
