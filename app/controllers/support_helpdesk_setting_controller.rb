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

class SupportHelpdeskSettingController < ApplicationController
  include SupportHelpdeskSettingHelper

  unloadable
  layout 'admin'

  before_filter :require_admin

  def index
  	@settings = SupportHelpdeskSetting.includes(:project, :tracker)

  	respond_to do |format|
  		format.html
  	end
  end

  def new
  	@setting = SupportHelpdeskSetting.new
    get_for_new_edit

  	respond_to do |format|
  		format.html
  	end
  end

  def create
    @setting = SupportHelpdeskSetting.new(params[:support_helpdesk_setting])

    respond_to do |format|
      if @setting.save
        format.html { redirect_to(support_helpdesk_settings_url, :notice => "Support setting successfully created.")}
      else
        get_for_new_edit
        format.html {render :action => "new"}
      end
    end
  end

  def edit
    @setting = SupportHelpdeskSetting.find params[:id]
    get_for_new_edit

    respond_to do |format|
      format.html
    end
  end

  def update
    @setting = SupportHelpdeskSetting.find params[:id]

    respond_to do |format|
      if @setting.update_attributes(params[:support_helpdesk_setting])
        format.html { redirect_to(support_helpdesk_settings_url, :notice => "Support setting successfully updated.")}
      else
        get_for_new_edit
        format.html {render :action => "edit"}
      end
    end
  end

  def activate
    @setting = SupportHelpdeskSetting.find params[:id]

    if @setting.active == true
      @setting.active = false
    else
      @setting.active = true
    end

    respond_to do |format|
      if @setting.save
        format.html {redirect_to(support_helpdesk_settings_url, :notice => "Setting updated successfully.")}
      else
        format.html {redirect_to(support_helpdesk_settings_url, :error => "Could not update setting.")}
      end
    end
  end

  def destroy
    @setting = SupportHelpdeskSetting.find params[:id]

    @setting.destroy

    respond_to do |format|
      format.html {redirect_to(support_helpdesk_settings_url, :notice => "Setting deleted.")}
    end
  end

  private
  def get_for_new_edit
    @projects = Project.order("name")
    @trackers = Tracker.all
    @issue_custom_fields = CustomField.where(:type => "IssueCustomField")
    @project_custom_fields = CustomField.where(:type => "ProjectCustomField")
    @groups = Group.all
    @users = User.where("type != ?", "AnonymousUser")
    @groups_users = @users + @groups
    @statuses = IssueStatus.all
    @priorities = IssuePriority.all

    # get list of templates to select for emails
    @template_files = Dir[File.join(Setting.plugin_support_helpdesk['support_template_path'], "*.text.erb")].reject do |f|
      f == '.' || f == '..' || f.split("/").last[0] == "_"
    end.map do |f|
      name = f.split("/").last.split(".").first
      [name, name]
    end
  end
end
