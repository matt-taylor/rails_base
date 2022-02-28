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

  def self.___execute_initializer___?
    # Fixes rails 6 changes to ARGV's -- dont reun initializers during rake tasks
    return false if Rake.application.top_level_tasks.any? { |task| task.include?(":") } rescue nil

    # Only execute when not doing DB actions
    boolean = defined?(ARGV) ? true : false  # for when no ARGVs are provided, we know its a railsc or rails s explicit
    boolean = false if boolean && ARGV[0]&.include?('db') # when its the DB rake tasks
    boolean = false if boolean && ARGV[0]&.include?('asset') # when its an asset
    boolean = false if boolean && ARGV[0]&.include?(':') # else this delim should never be included
    boolean = false if ENV['SKIP_CUSTOM_INIT']=='true' # explicitly set the variable to skip shit

    boolean
  end

  def self.url_routes
    Rails.application.routes.url_helpers
  end

  def self.app_name
    if ::Rails::VERSION::MAJOR >= 6
      ::Rails.application.class.module_parent_name
    else
      ::Rails.application.class.parent_name
    end
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
