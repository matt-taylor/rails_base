# frozen_string_literal: true

module RailsBase::Mfa::Totp
  module Helper
    def secret
      context.otp_secret || user.reload.otp_secret
    end

    def otp
      @otp ||= ROTP::TOTP.new(secret)
    end

    def current_code
      otp.at(Time.now)
    end

    def lgp
      @lgp ||= "[#{user.full_name}:(#{user.id})] :"
    end
  end
end
