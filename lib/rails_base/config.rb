require 'rails_base/configuration/admin'
require 'rails_base/configuration/mfa'
require 'rails_base/configuration/authentication'
require 'rails_base/configuration/redis'

module RailsBase
  class Config
    attr_reader :admin, :mfa, :auth, :redis
    def initialize
      @admin = Configuration::Admin.new
      @mfa = Configuration::Mfa.new
      @auth = Configuration::Authentication.new
      @redis = Configuration::Redis.new
    end

    def validate_configs!
      admin.validate!
      mfa.validate!
      auth.validate!
      redis.validate!
    end

    def reset_config!
      admin.assign_default_values!
      mfa.assign_default_values!
      auth.assign_default_values!
      redis.assign_default_values!
    end
  end
end
