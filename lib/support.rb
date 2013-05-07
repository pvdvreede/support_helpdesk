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

# setup namespaces
module Support
  module Participants
  end
end

# add requires
require "support/handler"
require "support/helpers/attachments"
require "support/helpers/emails"
require "support/helpers/misc"

require "support/pipelines/pipeline_base"
require "support/pipelines/ignore_pipeline"
require "support/pipelines/ignore_own_email_pipeline"
require "support/pipelines/ignore_domain_pipeline"
require "support/pipelines/get_project_pipeline"
require "support/pipelines/get_email_body_pipeline"
require "support/pipelines/support_pipeline"
require "support/pipelines/update_issue_pipeline"
require "support/pipelines/create_issue_pipeline"
require "support/pipelines/add_email_attachment_pipeline"
require "support/pipelines/update_times_pipeline"


require "support/hooks/journal_hook_listener"
require "support/hooks/support_hook_listener"

require "support/participants/base_participant"
require "support/participants/get_global_settings"
require "support/participants/get_support_settings"
require "support/participants/create_issue_body"
require "support/participants/check_from_exclusions"
require "support/participants/check_subject_exclusions"
require "support/participants/create_support_issue"
require "support/participants/update_support_issue"
require "support/participants/search_project"
require "support/participants/search_current_issue"
require "support/participants/add_email_attachment"

require "support/workflow"

# create array of plugins to add
Support::Handler.pipelines = [
  Support::Pipeline::IgnorePipeline.new("Ignore"),
  Support::Pipeline::GetEmailBodyPipeline.new("Get email body"),
  Support::Pipeline::UpdateIssuePipeline.new("Update issue"),
  Support::Pipeline::SupportPipeline.new("Support finder"),
  Support::Pipeline::IgnoreOwnEmailPipeline.new("Ignore own email"),
  Support::Pipeline::IgnoreDomainPipeline.new("Ignore Domain"),
  Support::Pipeline::GetProjectPipeline.new("Get project"),
  Support::Pipeline::CreateIssuePipeline.new("Create issue"),
  Support::Pipeline::AddEmailAttachmentPipeline.new("Attach emails"),
  Support::Pipeline::UpdateTimesPipeline.new("Update times")
]

