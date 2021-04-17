require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Redis < Base
      URL_PROC = Proc.new do |val|
        redacted_uri = URI(val)
        redacted_uri.user = nil
        redacted_uri.password = nil
        redacted_uri
      end
      DEFAULT_VALUES = {
        admin_action: {
          type: :string,
          default: ENV.fetch('REDIS_URL',''),
          decipher: URL_PROC,
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
