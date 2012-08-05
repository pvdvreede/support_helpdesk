# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
#match 'support/settings' => 'SupportHelpdeskSetting#index'
#match 'support/settings/new' => 'SupportHelpdeskSetting#new', :as => :new_support_helpdesk_setting

resources :support_helpdesk_setting, :path => '/support/settings'