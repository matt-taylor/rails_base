# frozen_string_literal: true

module RailsBase::Mfa::Sms
  class Remove < RailsBase::ServiceBase
    delegate :password, to: :context
    delegate :session_mfa_user_id, to: :context
    delegate :current_user, to: :context
    delegate :sms_code, to: :context
    delegate :mfa_event, to: :context

    def call
      password_result = RailsBase::Authentication::AuthenticateUser.(email: current_user.email, current_user: current_user, password: password)
      if password_result.failure?
        log(level: :debug, msg: "Password validation failed. Unable to continue")
        context.fail!(message: password_result.message)
      end

      validate_code = Validate.(mfa_event:,sms_code:, session_mfa_user_id:, current_user:)

      if validate_code.failure?
        log(level: :warn, msg: "Unable to confirm SMS OTP code. Will not remove")
        context.fail!(message: "Incorrect One Time Password Code")
      end

      current_user.update!(mfa_sms_enabled: false, last_mfa_sms_login: nil)
    end

    def validate!
      raise 'Expected the current_user passed' if current_user.nil?
      raise 'Expected the sms_code passed' if sms_code.nil?
      raise 'session_mfa_user_id is not present' if session_mfa_user_id.nil?
      raise 'password is not present' if password.nil?
    end
  end
end
