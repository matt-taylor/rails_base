# frozen_string_literal: true

module RailsBase::Mfa::Strategy
  class TimeBased < Base
    def self.description
      "MFA is required every #{RailsBase.config.mfa.reauth_duration}"
    end

    def require_mfa?(mfa_last_used:, **)
      if mfa_last_used.nil?
        log(level: :info, msg: "#{user_prepend} : User has not succesfully logged into mfa")
        return true
      end

      log(level: :info, msg: "#{user_prepend} : User last used mfa #{mfa_last_used.utc} (vs #{Time.now.utc})")
      required_line = mfa_last_used.utc + RailsBase.config.mfa.reauth_duration
      log(level: :info, msg: "#{user_prepend} : User required to reauth after #{required_line}")
      status = required_line < Time.now.utc
      log(level: :info, msg: "#{user_prepend} : User required to reauth? #{status}")

      status
    end
  end
end
