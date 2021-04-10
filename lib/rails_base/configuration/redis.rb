require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Redis < Base
        admin_action: { type: :string, default: ENV.fetch('REDIS_URL','') },
        admin_action_namespace: { type: :string_nil, default: nil },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
