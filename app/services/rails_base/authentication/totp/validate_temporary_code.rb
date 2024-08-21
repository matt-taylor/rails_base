module RailsBase::Authentication::Totp
  class ValidateTemporaryCode < RailsBase::ServiceBase
    delegate :user, to: :context
    delegate :otp_code, to: :context

    def call
      valid_code = ValidateCode.(user: user, otp_code: otp_code, otp_secret: current_secret)
      if valid_code.failure?
        context.fail!(message: valid_code.message)
      end

      log(level: :info, msg: "User[#{user.id}:#{user.full_name}] correctly validated authenticator code. Persisting")
      user.persist_otp_metadata!

      if user.otp_backup_codes.empty?
        backup_codes = user.generate_otp_backup_codes!
        log(level: :info, msg: "User[#{user.id}:#{user.full_name}]'s first authenticator added. Generating Backup Codes. Will also return backup codes to user")
        context.backup_codes = backup_codes
      else
        log(level: :warn, msg: "User[#{user.id}:#{user.full_name}]'s added additional Authenticator. Will NOT provide backup codes")
      end
    end

    def current_secret
      @current_secret ||= user.otp_metadata(safe: true, use_existing_temp: true)[:secret]
    end

    def validate!
      raise "Expected user to be a User. " unless User === user
      raise "Expected otp_code to be present" if otp_code.nil?
    end
  end
end
