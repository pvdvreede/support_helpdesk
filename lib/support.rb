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

  module Hooks
  end

  module Patches
  end
end

# add requires
require "support/pop"
require "support/hooks/journal_hook_listener"
require "support/hooks/support_hook_listener"
require "support/patches/issue_patch"

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
require "support/participants/create_support_message_id"
require "support/participants/send_email"
require "support/participants/set_email_reply"

require "support/workflow"
