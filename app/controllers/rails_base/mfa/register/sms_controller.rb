# frozen_string_literal: true

module RailsBase::Mfa::Register
  class SmsController < RailsBaseApplicationController
    before_action :authenticate_user!
    before_action :validate_mfa_token!, only: [:sms_removal, :sms_confirmation]
    before_action :json_validate_current_user!, only: [:sms_registration]

    # POST mfa/register/sms
    def sms_registration
      result = RailsBase::Authentication::UpdatePhoneSendVerification.call(user: current_user, phone_number: params[:phone_number])
      if result.failure?
        render :json => { error: I18n.t('request_response.teapot.fail'), msg: result.message }.to_json, :status => 418
        return
      end
      session[:mfa_randomized_token] = result.mfa_randomized_token
      render :json => { status: :success, message: I18n.t('request_response.teapot.valid') }
    end

    # POST mfa/register/sms/validate
    def sms_confirmation
      mfa_validity = RailsBase::Mfa::Sms::Validate.call(current_user: current_user, params: params, session_mfa_user_id: @token_verifier.user_id)
      if mfa_validity.failure?
        redirect_to RailsBase.url_routes.user_settings_path, alert: I18n.t('authentication.confirm_phone_registration.fail', message: mfa_validity.message)
        return
      end

      current_user.update!(mfa_sms_enabled: true)
      redirect_to RailsBase.url_routes.user_settings_path, notice: "Successfully added SMS as an MFA option on your account"
    end

    # DELETE mfa/register/sms
    def sms_removal
      result = RailsBase::Mfa::Sms::Remove.(current_user: current_user, session_mfa_user_id: @token_verifier.user_id, password: params[:password], sms_code: params[:sms_code])
      if result.success?
        flash[:notice] = "Successfully removed SMS as an MFA option on your account"
      else
        flash[:alert] = result.message
      end

      redirect_to RailsBase.url_routes.user_settings_path
    end
  end
end
