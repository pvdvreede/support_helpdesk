# Support Helpdesk - Redmine plugin
# Copyright (C) 2012 Paul Van de Vreede
#
# This file is part of Support Helpdesk.
#
# Support Helpdesk is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Support Helpdesk is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Support Helpdesk.  If not, see <http://www.gnu.org/licenses/>.

class SupportHelpdeskSetting < ActiveRecord::Base
  unloadable

  belongs_to :project
  belongs_to :tracker
  belongs_to :issue_status
  belongs_to :priority, :class_name => 'IssuePriority', :foreign_key => 'priority_id'
  has_many :issues_support_settings, :dependent => :destroy
  has_many :issues, :through => :issues_support_settings

  validates :new_status_id, :presence => true
  validates :project_id, :presence => true
  validates :author_id, :presence => true
  validates :to_email_address, :presence => true
  validates :from_email_address, :presence => true
  validates :tracker_id, :presence => true
  validates :reply_email_custom_field_id, :presence => true
  validates :type_custom_field_id, :presence => true
  validates :created_template_name, :presence => true
  validates :closed_template_name, :presence => true
  validates :question_template_name, :presence => true
  validates :name, :presence => true
  validates :assignee_group_id, :presence => true
  validates :priority_id, :presence => true

  validates_associated :project
  validates_associated :tracker
  validates_associated :issue_status
  validates_associated :priority

  scope :active, where(:active => true)

  def is_ignored_email_domain(email)
    # if there are no domains to ignore return
    return false if self.domains_to_ignore.nil?
    
    #other split the domains and check
    domain_array = self.domains_to_ignore.downcase.split(";")
    if domain_array.include?(email.from[0].split('@')[1].downcase)
      return true
    end

    false
  end

  def get_email_reply_string(email)
    return email.from[0] if not self.reply_all_for_outgoing

    #build semicolon string from all fields if not the support email
    email_array = email.to.to_a + email.from.to_a + email.cc.to_a

    email_array.find_all { |e| e.downcase unless e.downcase == self.to_email_address.downcase }.join("; ")
  end
end
