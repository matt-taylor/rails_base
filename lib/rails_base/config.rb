require 'rails_base/configuration/admin'
require 'rails_base/configuration/mfa'
require 'rails_base/configuration/authentication'
require 'rails_base/configuration/redis'
require 'rails_base/configuration/owner'

module RailsBase
  class Config
    attr_reader :admin, :mfa, :auth, :redis, :owner
    def initialize
      @admin = Configuration::Admin.new
      @mfa = Configuration::Mfa.new
      @auth = Configuration::Authentication.new
      @redis = Configuration::Redis.new
      @owner = Configuration::Owner.new
    end

    def validate_configs!
      admin.validate!
      mfa.validate!
      auth.validate!
      redis.validate!
      owner.validate!
    end

    def reset_config!
      admin.assign_default_values!
      mfa.assign_default_values!
      auth.assign_default_values!
      redis.assign_default_values!
      owner.assign_default_values!
    end
  end
end
