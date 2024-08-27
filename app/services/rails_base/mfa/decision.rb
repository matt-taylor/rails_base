# frozen_string_literal: true

module RailsBase::Mfa
  MFA_DECISIONS = [OTP = :otp, SMS = :sms, NONE = :none]
  class Decision < RailsBase::ServiceBase
    delegate :user, to: :context

    def call
      if RailsBase.config.mfa.enable?
        if user.mfa_otp_enabled
          execute_otp
        elsif user.mfa_sms_enabled
          execute_sms
        else
          execute_nil
        end
      else
        execute_nil
      end
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

      if require_mfa && execute?
        sms_result = RailsBase::Mfa::Sms::Send.(user: user, expires_at: 5.minutes.from_now)
        # Prolly need to do validation things to make sure it got sent
      else
        log(level: :warn, msg: "MFA is required on User. `execute=true` param must be passed to send SMS code to user")
      end

      context_clues(type: SMS, require_mfa: require_mfa)
    end

    def execute_nil
      log(level: :info, msg: "User/APP does not have any MFA type enabledmfa. Skipping")
      context_clues(type: nil, require_mfa: require_mfa)
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
