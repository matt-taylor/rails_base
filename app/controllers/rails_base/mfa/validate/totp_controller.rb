# frozen_string_literal: true

module RailsBase::Mfa::Validate
  class TotpController < RailsBaseApplicationController
    before_action :validate_mfa_token!

    # GET mfa/validate/totp/login
    def totp_login_input; end

    # POST mfa/validate/totp/login
    def totp_login
      user = User.find(@token_verifier.user_id)
      mfa_validity = ::RailsBase::Mfa::Totp::ValidateCode.(user: user, otp_code: params[:totp_code])
      if mfa_validity.failure?
        redirect_to(RailsBase.url_routes.mfa_evaluation_path(type: RailsBase::Mfa::OTP), alert: mfa_validity.message)
        return
      end

      user.set_last_mfa_otp_login!

      sign_in(mfa_validity.user)
      redirect_to RailsBase.url_routes.authenticated_root_path, notice: "Welcome #{mfa_validity.user.full_name}"
    end
  end
end
