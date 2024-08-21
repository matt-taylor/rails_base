module RailsBase
  class MfaAuthController < RailsBaseApplicationController
    before_action :validate_token, only: [:mfa_code, :mfa_code_verify, :resend_mfa]

    # POST /totp
    def totp_secret
      result = RailsBase::Authentication::Totp::OtpMetadata.(user: current_user)
      if result.success?
        render json: result.metadata
      else
        render json: { status: result.message }, status: 400
      end
    end

    # POST /totp/validate
    def totp_validate
      result = RailsBase::Authentication::Totp::ValidateTemporaryCode.(user: current_user, otp_code: params[:totp_code])
      if result.success?
        flash[:notice] = "Successfully added an Authenticator for TOTP to #{RailsBase.app_name}"
      else
        flash[:alert] = "Something Went Wrong! Failed to add an Authenticator for TOTP to #{RailsBase.app_name}. Please try again"
      end

      redirect_to RailsBase.url_routes.user_settings_path
    end

    # GET /mfa_verify
    def mfa_code
      @masked_phone = User.find(@token_verifier.user_id).masked_phone
    end

    # POST /mfa_verify
    def mfa_code_verify
      mfa_validity = RailsBase::Authentication::MfaValidator.call(params: params, session_mfa_user_id: @token_verifier.user_id)
      if mfa_validity.failure?
        redirect_to(mfa_validity.redirect_url, alert: mfa_validity.message)
        return
      end

      mfa_validity.user.set_last_mfa_login!

      sign_in(mfa_validity.user)
      redirect_to RailsBase.url_routes.authenticated_root_path, notice: "Welcome #{mfa_validity.user.full_name}"
    end

    # POST /mfa_verify
    def resend_mfa
      user = User.find(@token_verifier.user_id)
      mfa_token = RailsBase::Authentication::SendLoginMfaToUser.call(user: user)
      if mfa_token.failure?
        flash[:error] = mfa_token.message
        session[:mfa_randomized_token] = nil
        redirect_to RailsBase.url_routes.new_user_session_path, email: params.dig(:user,:email), alert: mfa_token.message
        return
      end
      expired_at = Time.zone.parse(@token_verifier.expires_at)
      session[:mfa_randomized_token] =
        RailsBase::Authentication::MfaSetEncryptToken.call(user: user, expires_at: expired_at).encrypted_val

      redirect_to RailsBase.url_routes.mfa_code_path, notice: "MFA has been sent via SMS to number on file"
    end

    def validate_token
      @token_verifier =
        RailsBase::Authentication::SessionTokenVerifier.call(mfa_randomized_token: session[:mfa_randomized_token])
      return if @token_verifier.success?

      redirect_to RailsBase.url_routes.new_user_session_path, alert: @token_verifier.message
      return false
    end
  end
end
