require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class AppUrl < Base

      DEFAULT_VALUES = {
        base_url: {
          type: :string,
          default: ENV.fetch('BASE_URL', 'http://localhost'),
          description: 'Base url. Used for things like SSO.'
        },
        base_port: {
          type: :string_nil,
          default: ENV.fetch('BASE_URL_PORT', nil),
          description: 'Base port. Used for things like SSO.'
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
