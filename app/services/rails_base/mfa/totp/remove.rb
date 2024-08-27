# frozen_string_literal: true

module RailsBase::Mfa::Totp
  class Remove < RailsBase::ServiceBase
    include Helper

    delegate :user, to: :context
    delegate :otp_code, to: :context
    delegate :password, to: :context

    def call
      password_result = RailsBase::Authentication::AuthenticateUser.(email: user.email, current_user: user, password: password)

      if password_result.failure?
        log(level: :debug, msg: "#{lgp} Password validation failed. Unable to continue")
        context.fail!(message: password_result.message)
      end

      valid_code = ValidateCode.(user: user, otp_code: otp_code)
      if valid_code.failure?
        log(level: :debug, msg: "#{lgp} Code Validation failed.")
        context.fail!(message: "#{valid_code.message}. Please try again.")
      end

      begin
        user.reset_otp!
        log(level: :info, msg: "#{lgp} TOTP successfully removed from User Account")
      rescue => e
        context.fail!("Yikes! Unknown error occured. TOTP was not removed from the account.")
      end
    end

    def validate!
      raise "Expected user to be a User." unless User === user
      raise "Expected otp_code to be present" if otp_code.nil?
      raise "Expected password to be present" if password.nil?
    end
  end
end

