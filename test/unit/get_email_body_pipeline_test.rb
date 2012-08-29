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

class GetEmailBodyPipelineTest < ActiveSupport::TestCase

  def test_decoding_multipart_email
    mail = load_email "multipart_email.eml"

    pipe = Support::Pipeline::GetEmailBodyPipeline.new("Get email body")

    return_context = create_and_run_pipeline(pipe, mail)

    assert_equal "This is the text plain email.", return_context[:body], "The body was not parsed correctly"
  end

  def test_decoding_multipart_email_reply_gmail
    mail = load_email "multipart_gmail_reply_email.eml"

    pipe = Support::Pipeline::GetEmailBodyPipeline.new("Get email body")

    return_context = create_and_run_pipeline(pipe, mail)

    assert_equal "This is the real text.\r\n\r\nfrom,\r\n\r\nMe\r\n\r\n", return_context[:body], "The body was not parsed correctly"
  end

  def test_decoding_multipart_email_reply_outlook
    mail = load_email "multipart_outlook_reply_email.eml"

    pipe = Support::Pipeline::GetEmailBodyPipeline.new("Get email body")

    return_context = create_and_run_pipeline(pipe, mail)

    assert_equal "This is the real text.\r\n\r\nfrom,\r\n\r\nMe\r\n\r", return_context[:body], "The body was not parsed correctly"
  end
end