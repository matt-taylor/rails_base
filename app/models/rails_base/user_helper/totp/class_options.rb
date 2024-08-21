# frozen_string_literal: true

module RailsBase
  module UserHelper
    module Totp
      module ClassOptions
        def totp_drift_ahead
          RailsBase.config.totp.allowed_drift_ahead || RailsBase.config.totp.allowed_drift
        end

        def totp_drift_behind
          RailsBase.config.totp.allowed_drift_behind || RailsBase.config.totp.allowed_drift
        end

        def generate_otp_secret(otp_secret_length = RailsBase.config.totp.secret_code_length)
          ROTP::Base32.random_base32(otp_secret_length)
        end
      end
    end
  end
end



