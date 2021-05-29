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
require 'rails_base/configuration/active_job'

module RailsBase
  class Config
    VARIABLES = {
      admin: nil,
      mfa: nil,
      auth: :authentication,
      redis: nil,
      owner: nil,
      mailer: nil,
      exceptions_app: nil,
      app: nil,
      appearance: nil,
      user: nil,
      active_job: nil,
      login_behavior: nil
    }
    attr_reader *VARIABLES.keys

    def initialize
      VARIABLES.each do |variable, override|
        klass_name = (override || variable).to_s.camelize
        klass = "RailsBase::Configuration::#{klass_name}".constantize
        instance_variable_set(:"@#{variable}", klass.new)
      end
    end

    def validate_configs!
      VARIABLES.keys.each do |var|
        send(var).validate!
      end
    end

    def reset_config!
      VARIABLES.keys.each do |var|
        send(var).assign_default_values!
      end
    end
  end
end
