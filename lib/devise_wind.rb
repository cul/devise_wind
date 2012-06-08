require 'warden'
require 'devise'
require 'nokogiri'
require 'devise_wind/engine'
require 'devise_wind/mixins/urls'
require 'devise_wind/model'
require 'devise_wind/strategy'
require 'devise_wind/version'
module DeviseWind
  def self.add_routes(router, options={})
    router.devise_for :users, :controllers => {:sessions => 'sessions'}
  end
end

Devise.add_module :wind_authenticatable,
  :strategy => true,
  :model => 'devise_wind/model',
  :controller => :sessions,
  :route => :session