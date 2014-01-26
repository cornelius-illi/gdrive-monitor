# -*- coding: utf-8 -*-
SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |primary|
    primary.dom_class = 'right'
    primary.item :key_0, 'Sign in with Google', user_omniauth_authorize_path(:google_oauth2), :class => 'has-form', :link => {:class => 'button'}, :unless => Proc.new { user_signed_in? }
    primary.item :key_1, 'Logout', destroy_user_session_path, :method => 'delete', :class => 'has-form', :link => {:class => 'button'}, :if => Proc.new { user_signed_in? }
  end
end