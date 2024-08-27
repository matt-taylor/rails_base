# frozen_string_literal: true

module RailsBase::Mfa::Register
  class TotpController < RailsBaseApplicationController
    # DELETE mfa/register/totp
    def totp_remove
      result = RailsBase::Mfa::Totp::Remove.(password: params[:password], user: current_user, otp_code: params[:totp_code])

      if result.success?
        flash[:notice] = "Successfully Removed TOTP Authentication to #{RailsBase.app_name}"
      else
        flash[:alert] = "Something Went Wrong! #{result.message}"
      end

      redirect_to RailsBase.url_routes.user_settings_path
    end

    # POST mfa/register/totp
    def totp_secret
      result = RailsBase::Mfa::Totp::OtpMetadata.(user: current_user)
      if result.success?
        render json: result.metadata
      else
        render json: { status: result.message }, status: 400
      end
    end

    # POST mfa/register/totp/validate
    def totp_validate
      result = RailsBase::Mfa::Totp::ValidateTemporaryCode.(user: current_user, otp_code: params[:totp_code])
      if result.success?
        flash[:notice] = "Successfully added an Authenticator for TOTP to #{RailsBase.app_name}"
      else
        flash[:alert] = "Something Went Wrong! Failed to add an Authenticator for TOTP to #{RailsBase.app_name}. Please try again"
      end

      redirect_to RailsBase.url_routes.user_settings_path
    end
  end
end
