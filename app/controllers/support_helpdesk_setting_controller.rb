class SupportHelpdeskSettingController < ApplicationController
  unloadable

  #before_filter :authorize

  def index
  	@settings = SupportHelpdeskSetting.all

  	respond_to do |format|
  		format.html
  	end
  end

  def new
  	@setting = SupportHelpdeskSetting.new
  	@projects = Project.all
  	@trackers = Tracker.all
  	@issue_custom_fields = CustomField.where(:type => "IssueCustomField")
  	@project_custom_fields = CustomField.where(:type => "ProjectCustomField")

  	# get list of templates to select for emails
  	@template_files = []
  	Dir.foreach("#{File.expand_path(File.dirname(__FILE__))}/../views/support_helpdesk_mailer") do |f|
  		if not f == '.' and not f == '..'
  			name = f.split(".")[0]
  			@template_files << [name, name]
  		end
  	end

  	respond_to do |format|
  		format.html
  	end
  end

  def create
  end

  def edit
  end
end
