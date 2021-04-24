require 'rails_base/configuration/admin'
require 'rails_base/configuration/mfa'
require 'rails_base/configuration/authentication'
require 'rails_base/configuration/redis'
require 'rails_base/configuration/owner'
require 'rails_base/configuration/mailer'
require 'rails_base/configuration/exceptions_app'
require 'rails_base/configuration/app_url'
require 'rails_base/configuration/appearance'
require 'rails_base/configuration/user'

module RailsBase
  class Config
    attr_reader :admin, :mfa, :auth, :redis, :owner, :mailer, :exceptions_app, :app_url, :appearance, :user
    def initialize
      @admin = Configuration::Admin.new
      @mfa = Configuration::Mfa.new
      @auth = Configuration::Authentication.new
      @redis = Configuration::Redis.new
      @owner = Configuration::Owner.new
      @mailer = Configuration::Mailer.new
      @exceptions_app = Configuration::ExceptionsApp.new
      @app_url = Configuration::AppUrl.new
      @appearance = Configuration::Appearance.new
      @user = Configuration::User.new
    end

    def validate_configs!
      admin.validate!
      mfa.validate!
      auth.validate!
      redis.validate!
      owner.validate!
      mailer.validate!
      exceptions_app.validate!
      app_url.validate!
      appearance.validate!
      user.validate!
    end

    def reset_config!
      admin.assign_default_values!
      mfa.assign_default_values!
      auth.assign_default_values!
      redis.assign_default_values!
      owner.assign_default_values!
      mailer.assign_default_values!
      exceptions_app.assign_default_values!
      app_url.assign_default_values!
      appearance.assign_default_values!
      user.assign_default_values!
    end
  end
end
