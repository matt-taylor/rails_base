# frozen_string_literal: true

module RailsBase::Mfa
  MFA_DECISIONS = [
    OTP = :otp,
    SMS = :sms,
    NONE = :none
  ]
end
