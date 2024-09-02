require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Twilio < Base

      MFA_TYPE_OPTIONS = [ DEFAULT_TYPE = :totp, :twilio ]
      MFA_MIN_LENGTH = 4
      MFA_MAX_LENGTH = 8
      DEFAULT_VALUES = {
        enable: {
          type: :boolean,
          default: ENV.fetch('MFA_ENABLE', 'true')=='true',
          description: 'Allow twilio as an MFA option.',
        },
        mfa_length: {
          type: :integer,
          default: 5,
          custom: ->(val) { val > MFA_MIN_LENGTH && val < MFA_MAX_LENGTH },
          msg: "Must be an integer greater than #{MFA_MIN_LENGTH} and less than #{MFA_MAX_LENGTH}",
          description: 'Length of MFA verification',
        },
        twilio_sid: {
          type: :string,
          default: ENV.fetch('TWILIO_ACCOUNT_SID',''),
          secret: true,
          description: 'Twilio SID',
        },
        twilio_auth_token: {
          type: :string,
          default: ENV.fetch('TWILIO_AUTH_TOKEN', ''),
          secret: true,
          description: 'Twilio Auth Token',
        },
        twilio_from_number: {
          type: :string,
          default: ENV.fetch('TWILIO_FROM_NUMBER', ''),
          description: 'Number that we send MFA\'s From',
        },
        twilio_velocity_max: {
          type: :integer,
          default: ENV.fetch('TWILIO_VELOCITY_MAX', 5).to_i,
          description: 'Max number of SMS we send to a user in a sliding window',

        },
        twilio_velocity_max_in_frame: {
          type: :duration,
          default: ENV.fetch('TWILIO_VELOCITY_MAX_IN_FRAME', 1).to_i.hours,
          description: 'Sliding window for twilio_velocity_max',
        },
        twilio_velocity_frame: {
          type: :duration,
          default: ENV.fetch('TWILIO_VELOCITY_FRAME', 5).to_i.hours,
          description: 'Debug purposes. How long to keep admin_velocity_max attempts',
        },
        active_job_queue: {
          type: :string,
          default: 'twilio_sms',
          description: 'The active job queue to send twilio messages from. Ensure that adapter is bound to the queue',
        }
      }
      attr_accessor *DEFAULT_VALUES.keys

      private

      def custom_validations
        enforce_twilio!
      end

      def enforce_twilio!
        return unless enable == true

        return if twilio_sid.present? &&
          twilio_auth_token.present? &&
          twilio_from_number.present?

        raise InvalidConfiguration, "twilio_sid twilio_auth_token twilio_from_number need to be present when `mfa.enabled`"
      end

      def default_values
        DEFAULT_VALUES
      end
    end
  end
end
