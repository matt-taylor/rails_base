# frozen_string_literal: true

module RailsBase::Mfa
  MFA_DECISIONS = [
    OTP = :otp,
    SMS = :sms,
    NONE = :none
  ]

  def self.mfa_link(mfa:)
    case mfa
    when OTP
      { method: :get, link: RailsBase.url_routes.mfa_evaluation_path(type: mfa) }
    when SMS
      { method: :post, link: RailsBase.url_routes.sms_validate_send_path }
    end
  end
end
