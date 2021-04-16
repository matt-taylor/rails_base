require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Redis < Base
      DEFAULT_VALUES = {
        admin_action: {
          type: :string,
          default: ENV.fetch('REDIS_URL',''),
          description: 'Redis URL for Admin cache'
        },
        admin_action_namespace: {
          type: :string_nil,
          default: nil,
          description: 'Namespace used for admin cache'
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
