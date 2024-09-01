# frozen_string_literal: true

module RailsBase::Mfa
  MFA_DECISIONS = [
    OTP = :otp,
    SMS = :sms,
    NONE = :none
  ]

  def self.mfa_link(mfa:, mfa_event:)
    case mfa
    when OTP
      { method: :get, link: RailsBase.url_routes.mfa_with_event_path(mfa_event:, type: mfa) }
    when SMS
      { method: :post, link: RailsBase.url_routes.sms_validate_send_event_path(mfa_event:) }
    end
  end
end
