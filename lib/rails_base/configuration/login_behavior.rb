require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class LoginBehavior < Base

      DEFAULT_VALUES = {
        fallback_to_referred: {
          type: :boolean,
          default: true,
          description: 'Enable capturing requests context when login fails. Upon login, redirect user to page they tried to go to.',
        },
        email_max_use_verification:{
          type: :integer,
          default: 2,
          description: 'Maximum number of times User can click link for verifiaction',
        },
        email_max_use_forgot:{
          type: :integer,
          default: 2,
          description: 'Maximum number of times User can click link for forgot password flow',
        },
      }
      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
