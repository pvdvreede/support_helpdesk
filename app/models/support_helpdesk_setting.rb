class SupportHelpdeskSetting < ActiveRecord::Base
  unloadable

  has_many :issues_support_settings, :dependent => :destroy
  has_many :issues, :through => :issues_support_settings
end
