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

require 'rails_base/admin/action_cache'
require 'rails_base/config'

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

  def self.configure(&block)
    yield(config) if block_given?

    config.validate_configs!
  end

  def self.config
    @config ||= RailsBase::Config.instance
  end

  def self.appearance
    @appearance ||= config.appearance
  end

  def self.reset_config!
    config.reset_config!
  end

  AdminStruct = Struct.new(:original_attribute, :new_attribute, :user)
end
