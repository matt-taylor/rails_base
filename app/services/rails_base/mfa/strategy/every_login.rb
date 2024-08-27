# frozen_string_literal: true

module RailsBase::Mfa::Strategy
  class EveryLogin < Base
    def self.description
      "MFA is always requried"
    end

    def require_mfa?(...)
      log(level: :info, msg: "#{user_prepend} : Strategy dictates user must re-auth via MFA")
      true
    end
  end
end
