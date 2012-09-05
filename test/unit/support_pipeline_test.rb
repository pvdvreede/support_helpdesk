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

class SupportPipelineTest < ActiveSupport::TestCase
  self.fixture_path = File.dirname(File.expand_path(__FILE__)) + "/../fixtures/"
  fixtures :all

  def test_support_not_found
    mail = load_email "multipart_email.eml"
    mail.to = "nothing@nothing.com"

    pipe = Support::Pipeline::SupportPipeline.new("Support")

    assert_raise Support::PipelineProcessingError do
      return_context = create_and_run_pipeline(pipe, mail)
    end
  end

  def test_support_not_in_cc
    mail = load_email "multipart_email.eml"
    mail.to = "nothin@nothing.com"
    mail.cc = "test6@support.com"

    pipe = Support::Pipeline::SupportPipeline.new("Support")

    assert_raise Support::PipelineProcessingError do
      return_context = create_and_run_pipeline(pipe, mail)
    end

    mail.cc = "nothin@nothing.com"
    mail.to = "test6@support.com"

    return_context = create_and_run_pipeline(pipe, mail)

    assert_not_nil return_context[:support], "Support contect is nil"
    assert_equal 6, return_context[:support].id, "Not correct support object."
  end

  def test_support_not_in_to
    mail = load_email "multipart_email.eml"
    mail.cc = "nothin@nothing.com"
    mail.to = "test7@support.com"

    pipe = Support::Pipeline::SupportPipeline.new("Support")

    assert_raise Support::PipelineProcessingError do
      return_context = create_and_run_pipeline(pipe, mail)
    end

    mail.to = "nothin@nothing.com"
    mail.cc = "test7@support.com"

    return_context = create_and_run_pipeline(pipe, mail)

    assert_not_nil return_context[:support], "Support contect is nil"
    assert_equal 7, return_context[:support].id, "Not correct support object."
  end

  def test_support_in_to_and_cc
    mail = load_email "multipart_email.eml"
    mail.cc = "nothin@nothing.com"
    mail.to = "test@support.com"

    pipe = Support::Pipeline::SupportPipeline.new("Support")
    return_context = create_and_run_pipeline(pipe, mail)

    assert_not_nil return_context[:support], "Support contect is nil"
    assert_equal 1, return_context[:support].id, "Not correct support object."

    mail.to = "nothin@nothing.com"
    mail.cc = "test@support.com"

    return_context = create_and_run_pipeline(pipe, mail)

    assert_not_nil return_context[:support], "Support contect is nil"
    assert_equal 1, return_context[:support].id, "Not correct support object."
  end

  def test_email_quote_cleanse
    mail = load_email "multipart_email.eml"
    mail.cc = "nothin@nothing.com"
    mail.to = "'test@support.com'"

    pipe = Support::Pipeline::SupportPipeline.new("Support")
    return_context = create_and_run_pipeline(pipe, mail)

    assert_not_nil return_context[:support], "Support contect is nil"
    assert_equal 1, return_context[:support].id, "Not correct support object."
  end   

  def test_email_with_bcc_skipped
    mail = load_email "multipart_email.eml"
    mail.cc = ""
    mail.to = ""

    pipe = Support::Pipeline::SupportPipeline.new("Support")

    assert_raise Support::PipelineProcessingError do
      return_context = create_and_run_pipeline(pipe, mail)
    end
  end

end