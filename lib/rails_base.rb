require "rails_base/engine"

# explicitly require gems that provide assets
# when engine loads, this adds assets to Main apps ssets pipeline
# (Only a problem for lazy loaded non prod ENVs)
require 'jquery_mask_rails'
require 'allow_numeric'
require 'jquery-rails'
require 'coffee-rails'
require 'turbolinks'
require 'popper_js'
require 'bootstrap'
require 'sassc-rails'
require 'switch_user'
# RailsBase.url_routes.

module RailsBase
  def self.url_routes
    Rails.application.routes.url_helpers
  end

  def self.route_exist?(path)
    Rails.application.routes.recognize_path(path)
    true
  rescue StandardError, ActionController::RoutingError
    false
  end
end
