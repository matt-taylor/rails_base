# frozen_string_literal: true

module RailsBase::Mfa::Totp
  class ValidateCode < RailsBase::ServiceBase
    include Helper

    delegate :user, to: :context
    delegate :otp_code, to: :context

    def call
      return if validate_and_consume_otp

      context.fail!(message: "Invalid TOTP code")
    end

    def validate_and_consume_otp
      if user.consumed_timestep
        # reconstruct the timestamp of the last consumed timestep
        after_timestamp = user.consumed_timestep * otp.interval
      end

      if otp.verify(otp_code.gsub(/\s+/, ""), drift_behind: User.totp_drift_behind, drift_ahead: User.totp_drift_ahead, after: after_timestamp)
        log(level: :debug, msg: "#{lgp} Correct code provided")
        return consume_otp!
      else
        log(level: :debug, msg: "#{lgp} InValid code provided")
      end

      false
    end

    # An OTP cannot be used more than once in a given timestep
    # Storing timestep of last valid OTP is sufficient to satisfy this requirement
    def consume_otp!
      timestep = Time.now.utc.to_i / otp.interval
      if user.consumed_timestep != timestep
        user.consumed_timestep = timestep
        log(level: :debug, msg: "#{lgp} Consuming timestep based on code input")
        return user.save(validate: false)
      end

      log(level: :debug, msg: "#{lgp} Timestep for code was already consumed. Invalid code")
      false
    end

    def validate!
      raise "Expected user to be a User. " unless User === user
      raise "Expected otp_code to be present" if otp_code.nil?
      raise "Expected `otp_secret` passed in or `otp_secret` present on User" if secret.nil?
    end
  end
end
