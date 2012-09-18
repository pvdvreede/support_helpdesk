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

require File.dirname(File.expand_path(__FILE__)) + '/../test_helper'

class IgnoreOwnEmailPipelineTest < ActiveSupport::TestCase
  self.fixture_path = File.dirname(File.expand_path(__FILE__)) + "/../fixtures/"
  fixtures :all
  
  def test_warn_for_own_email
    mail = load_email "multipart_email.eml"
    mail.from = "test2@support.com"
    mail.to = "test2@support.com"

    pipe = Support::Pipeline::IgnoreOwnEmailPipeline.new("Ignore own email")

    pipe.context = {
      :support => SupportHelpdeskSetting.find(2),
      :email => mail
    }

    assert_raise Support::PipelineProcessingWarn do
      return_context = pipe.execute
    end
  end

  def test_continue_for_other_email
    mail = load_email "multipart_email.eml"
    mail.from = "someone@else.com"
    mail.to = "test2@support.com"

    pipe = Support::Pipeline::IgnoreOwnEmailPipeline.new("Ignore own email")

    pipe.context = {
      :support => SupportHelpdeskSetting.find(2),
      :email => mail
    }

    return_context = pipe.execute

    assert_not_nil return_context[:email], "The email of the context is nil."
  end

end