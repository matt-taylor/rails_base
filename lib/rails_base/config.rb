require 'rails_base/configuration/admin'
require 'rails_base/configuration/mfa'
require 'rails_base/configuration/authentication'
require 'rails_base/configuration/redis'
require 'rails_base/configuration/owner'
require 'rails_base/configuration/mailer'
require 'rails_base/configuration/exceptions_app'
require 'rails_base/configuration/app'
require 'rails_base/configuration/appearance'
require 'rails_base/configuration/user'
require 'rails_base/configuration/login_behavior'
require 'rails_base/configuration/sidekiq'

module RailsBase
  class Config
    VARIABLES = [
      :admin,
      :mfa,
      :auth,
      :redis,
      :owner,
      :mailer,
      :exceptions_app,
      :app,
      :appearance,
      :user,
      :sidekiq,
      :login_behavior
    ]
    attr_reader *VARIABLES

    def initialize
      @admin = Configuration::Admin.new
      @mfa = Configuration::Mfa.new
      @auth = Configuration::Authentication.new
      @redis = Configuration::Redis.new
      @owner = Configuration::Owner.new
      @mailer = Configuration::Mailer.new
      @exceptions_app = Configuration::ExceptionsApp.new
      @app = Configuration::App.new
      @appearance = Configuration::Appearance.new
      @user = Configuration::User.new
      @sidekiq = Configuration::Sidekiq.new
      @login_behavior = Configuration::LoginBehavior.new
    end

    def validate_configs!
      VARIABLES.each do |var|
        send(var).validate!
      end
    end

    def reset_config!
      VARIABLES.each do |var|
        send(var).assign_default_values!
      end
    end
  end
end
