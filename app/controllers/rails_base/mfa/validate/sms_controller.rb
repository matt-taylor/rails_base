# frozen_string_literal: true

module RailsBase::Mfa::Validate
  class SmsController < RailsBaseApplicationController
    before_action :validate_mfa_token!, only: [:sms_login_input, :sms_login]

    # POST mfa/validate/sms/send
    def sms_send
      if soft_validate_mfa_token(token: session[:mfa_randomized_token])
        user = User.find(@token_verifier.user_id)
      else
        session[:mfa_randomized_token] = nil
        if request.format.json?
          render json: { message: @token_verifier.message }, status: 400
        else
          # SMS SEND via HTML should only come from unauthed page
          flash[:alert] = @token_verifier.message

          redirect_to RailsBase.url_routes.new_user_session_path, email: params.dig(:user,:email)
        end
        return
      end

      if request.format.json?
        # When json, this will always come from an authenticated user
        # otherwise kick them out now!
        return unless authenticate_user!

        user = current_user
      end

      result = RailsBase::Mfa::Sms::Send.call(user: user)

      if result.success?
        session[:mfa_randomized_token] =
          RailsBase::Mfa::EncryptToken.call(user: user, expires_at: 2.minutes.from_now).encrypted_val
        msg = "SMS Code succesfully sent!"
        flash[:notice] = "SMS Code succesfully sent. Please check messages"
        status = 200
      else
        flash[:alert] = msg = "Unable to complete Request. #{result.message}"
        status = 400
      end


      if request.format.json?
        render json: { message: msg }, status: status
        flash.clear
      else
        redirect_to RailsBase.url_routes.mfa_evaluation_path(type: RailsBase::Mfa::SMS)
      end
    end

    # GET mfa/validate/sms/login
    def sms_login_input
      @masked_phone = User.find(@token_verifier.user_id).masked_phone
    end

    # POST mfa/validate/sms/login
    def sms_login
      mfa_validity = RailsBase::Mfa::Sms::Validate.call(params: params, session_mfa_user_id: @token_verifier.user_id)
      if mfa_validity.failure?
        redirect_to(mfa_validity.redirect_url, alert: mfa_validity.message)
        return
      end

      mfa_validity.user.set_last_mfa_sms_login!

      sign_in(mfa_validity.user)
      redirect_to RailsBase.url_routes.authenticated_root_path, notice: "Welcome #{mfa_validity.user.full_name}"
    end
  end
end
