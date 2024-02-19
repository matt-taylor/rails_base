require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

require 'rails_base'
require 'devise'

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults Rails::VERSION::STRING.to_f
    config.autoloader = :zeitwerk

    RailsBase.reloadable_paths!(relative_path: "app/models", skip_files: ["application_record.rb"])
  end
end

