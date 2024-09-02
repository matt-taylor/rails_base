# frozen_string_literal: true

module RailsBase::Mfa
  class Decision < RailsBase::ServiceBase
    delegate :user, to: :context

    def call
      unless RailsBase.config.mfa.enable?
        execute_nil("Application")
        return
      end

      if user.mfa_otp_enabled
        execute_otp
      elsif user.mfa_sms_enabled
        execute_sms
      else
        execute_nil("User")
      end

      available_mfa_options!
    end

    def available_mfa_options!
      mfa_options = []
      mfa_options << OTP if user.mfa_otp_enabled
      mfa_options << SMS if user.mfa_sms_enabled

      context.mfa_options = mfa_options
    end

    def execute_otp
      log(level: :info, msg: "MFA type OTP is enabled on user. Executing OTP workflow")
      result = reauth_strategy_class.(user: user, force: force_mfa, mfa_type: OTP, mfa_last_used: user.last_mfa_otp_login)
      require_mfa = result.request_mfa

      context_clues(type: OTP, require_mfa: require_mfa)
    end

    def execute_sms
      log(level: :info, msg: "MFA type SMS is enabled on user. Executing OTP workflow")
      result = reauth_strategy_class.(user: user, force: force_mfa, mfa_type: SMS, mfa_last_used: user.last_mfa_sms_login)
      require_mfa = result.request_mfa

      context_clues(type: SMS, require_mfa: require_mfa)
    end

    def execute_nil(classify)
      log(level: :info, msg: "#{classify} does not have any MFA type enabled. Skipping")
      context_clues(type: NONE, require_mfa: false)
    end

    def context_clues(type:, require_mfa:)
      context.mfa_type = type
      context.mfa_require = require_mfa
    end

    def force_mfa
      context.force_mfa.nil? ? false : context.force_mfa
    end

    def reauth_strategy_class
      RailsBase.config.mfa.reauth_strategy
    end

    def validate!
      raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User
    end
  end
end
