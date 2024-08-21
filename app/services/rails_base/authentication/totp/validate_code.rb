module RailsBase::Authentication::Totp
  class ValidateCode < RailsBase::ServiceBase
    delegate :user, to: :context
    delegate :otp_code, to: :context

    def call
      valid_code = user.validate_and_consume_otp!(otp_code, params)
      log(level: :info, msg: "User [#{user.id}:#{user.full_name}] passed validity check? #{valid_code}")

      return if valid_code

      context.fail!(message: "Invalid TOTP code")
    end

    def params
      {
        bypass_require: true,
        otp_secret: context.otp_secret,
      }.compact
    end

    def validate!
      raise "Expected user to be a User. " unless User === user
      raise "Expected otp_code to be present" if otp_code.nil?
    end
  end
end
