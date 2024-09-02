require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Totp < Base

      DEFAULT_VALUES = {
        enable: {
          type: :boolean,
          default: true,
          description: "TOTP must be explicitly enabled per application"
        },
        secret_code_length: {
          type: :integer,
          default: 32,
          description: "The length of the secret to generate an OTP"
        },
        backup_code_length: {
          type: :integer,
          default: 64,
          description: "The length of each backup code provided"
        },
        backup_code_count: {
          type: :integer,
          default: 10,
          description: "The number of Backup codes generated if TOTP is cannot be solved.",
        },
        allowed_drift: {
          type: :integer,
          default: 30,
          description: "The allowed drift around the current timestamp.",
        },
        allowed_drift_behind:{
          type: :integer_nil,
          default: nil,
          description: "Allowed drift behind current timestamp. Takes precendence over allowed_drift",
        },
        allowed_drift_ahead:{
          type: :integer_nil,
          default: nil,
          description: "Allowed drift ahead current timestamp. Takes precendence over allowed_drift",
        },
        velocity_max: {
          type: :integer,
          default: 3,
          description: 'Max number of TOTP we allow a user to attempt in a sliding window',
        },
        velocity_max_in_frame: {
          type: :duration,
          default: 60.seconds,
          description: 'Sliding window for velocity_max',
        },
        velocity_frame: {
          type: :duration,
          default: 300.seconds,
          description: 'Debug purposes. How long to keep velocity_max attempts',
        },
      }
      attr_accessor *DEFAULT_VALUES.keys

      private

      def custom_validations
        if velocity_max_in_frame < max_behind || velocity_max_in_frame < max_ahead
          raise ArgumentError, "totp.velocity_max_in_frame must be greater than the allowed_drift"
        end

        if velocity_frame < velocity_max_in_frame
          raise ArgumentError, "totp.velocity_frame must be greater than totp.velocity_max_in_frame"
        end
      end

      def max_behind
        allowed_drift_ahead || allowed_drift
      end

      def max_ahead
        allowed_drift_behind || allowed_drift
      end
    end
  end
end
