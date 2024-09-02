# frozen_string_literal: true

module RailsBase::Mfa::Strategy
  class SkipEveryRequest < Base
    def self.description
      "MFA is never requried"
    end

    def require_mfa?(...)
      log(level: :info, msg: "#{user_prepend} : Strategy dictates user will never re-auth via MFA")
      false
    end
  end
end
