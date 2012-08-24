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

# add requires
require "support/handler"
require "support/pipelines/pipeline_base"
require "support/pipelines/ignore_pipeline"
require "support/pipelines/ignore_domain_pipeline"
require "support/pipelines/support_pipeline"

# create array of plugins to add
Support::Handler.pipelines = [
  Support::Pipeline::IgnorePipeline.new("Ignore"),
  Support::Pipeline::SupportPipeline.new("Support finder"),
  Support::Pipeline::IgnoreDomainPipeline.new("Ignore Domain")
]

