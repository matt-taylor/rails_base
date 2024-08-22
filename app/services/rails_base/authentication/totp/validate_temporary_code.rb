# frozen_string_literal: true

module RailsBase::Authentication::Totp
  class ValidateTemporaryCode < RailsBase::ServiceBase
    include Helper

    delegate :user, to: :context
    delegate :otp_code, to: :context

    def call
      valid_code = ValidateCode.(user: user, otp_code: otp_code, otp_secret: current_secret)
      if valid_code.failure?
        log(level: :debug, msg: "#{lgp} Code Validation failed. Will not persist temporary token")
        context.fail!(message: valid_code.message)
      end

      log(level: :info, msg: "#{lgp} correctly validated authenticator code. Persisting")
      user.persist_otp_metadata!
      if user.otp_backup_codes.empty?
        backup_codes = user.generate_otp_backup_codes!
        log(level: :info, msg: "#{lgp} first authenticator added. Generating Backup Codes. Will also return backup codes to user")
        context.backup_codes = backup_codes
      else
        log(level: :warn, msg: "#{lgp} added additional Authenticator. Will NOT provide backup codes")
      end
    end

    def current_secret
      @current_secret ||= user.reload.otp_metadata(safe: true, use_existing_temp: true)[:secret]
    end

    def validate!
      raise "Expected user to be a User. " unless User === user
      raise "Expected otp_code to be present" if otp_code.nil?
    end
  end
end
