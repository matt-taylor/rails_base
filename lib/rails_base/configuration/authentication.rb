require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Authentication < Base
      DEFAULT_SESSION = 60.days
      MIN_SESSION = 5.minutes

      DEFAULT_MFA_TIME = 7.day
      MIN_MFA_TIME = 1.day

      DEFAULT_VALUES = {
        session_timeout: {
          type: :duration,
          default: ENV.fetch('SESSION_TIMEOUT_IN_SECONDS', DEFAULT_SESSION).to_i.seconds,
          custom: ->(val) { val.to_i >= MIN_SESSION },
          msg: "session_timeout must be a duration. Greater than #{MIN_SESSION}",
          on_assignment: ->(val, _instance) { Devise.timeout_in = val },
          description: 'Debug purposes. How long to keep admin_velocity_max attempts',
        },
        session_timeout_warning: {
          type: :boolean,
          default: true,
          description: 'Display a timeout warning. When disabled, user will be logged out without warning',
        },
        mfa_time_duration: {
          type: :duration,
          default: DEFAULT_MFA_TIME,
          custom: ->(val) { val.to_i > MIN_MFA_TIME },
          msg: "mfa_time_duration must be a duration. Greater than #{MIN_MFA_TIME}",
          description: 'Max time between when MFA will be required',
        }
      }
      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
