
resources :support_helpdesk_settings, :controller => 'support_helpdesk_setting', :path => '/support/settings' do
  post 'activate', :on => :member
end