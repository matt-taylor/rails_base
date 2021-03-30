module RailsBase
  class SecondaryAuthenticationController < ApplicationController
    before_action :authenticate_user!, only: [:remove_phone_mfa, :confirm_phone_registration]

    before_action :validate_token!, only: [:resend_email, :wait, :confirm_phone_registration]

    before_action :json_validate_current_user!, only: [:phone_registration]

    # GET auth/wait
    def static
      return unless validate_token!(purpose: Authentication::Constants::SSOVE_PURPOSE)

      if flash[:notice].nil? && flash[:alert].nil?
        flash[:notice] = Authentication::Constants::STATIC_WAIT_FLASH
      end
    end

    def remove_me
    end

    def testing_route
      Rails.logger.error("This will cause an error to be thrown")
      raise ArgumentError, 'Boo'
    end

    # POST auth/resend_email
    def resend_email
      user = User.find @token_verifier.user_id
      email_verification = Authentication::SendVerificationEmail.call(user: user, reason: Authentication::Constants::SVE_LOGIN_REASON)
      params =
        if email_verification.failure?
          { alert: email_verification.message }
        else
          { notice: I18n.t('authentication.resend_email', email: user.email) }
        end
      redirect_to RailsBase.url_routes.auth_static_path, params
    end

    # GET auth/email/:data
    def email_verification
      verify = Authentication::SsoVerifyEmail.call(verification: params[:data])

      if verify.failure?
        redirect_to(verify.redirect_url, alert: verify.message)
        return
      end

      session[:mfa_randomized_token] = verify.encrypted_val
      redirect_to RailsBase.url_routes.login_after_email_path
    end

    # GET auth/login
    def after_email_login_session_new
      return unless validate_token!(purpose: Authentication::Constants::SSOVE_PURPOSE)

      @user = User.new
      if flash[:alert].nil? && flash[:notice].nil?
        flash[:notice] = I18n.t('authentication.after_email_login_session_new')
      end
    end

    # POST auth/login
    def after_email_login_session_create
      return unless validate_token!(purpose: Authentication::Constants::SSOVE_PURPOSE)

      flash[:notice] = nil
      flash[:alert] = nil
      authenticate = Authentication::AuthenticateUser.call(email: params[:user][:email], password: params[:user][:password])
      if authenticate.failure?
        flash[:alert] = authenticate.message
        @user = User.new(email: params[:user][:email])
        render :after_email_login_session_new
        return
      end

      sign_in(authenticate.user)
      flash[:notice] = I18n.t('authentication.after_email_login_session_create')
      redirect_to RailsBase.url_routes.authenticated_root_path
    end

    # POST auth/phone
    def phone_registration
      result = Authentication::UpdatePhoneSendVerification.call(user: current_user, phone_number: params[:phone_number])
      if result.failure?
        render :json => { error: I18n.t('request_response.teapot.fail'), msg: result.message }.to_json, :status => 418
        return
      end
      session[:mfa_randomized_token] = result.mfa_randomized_token

      render :json => { status: :success, message: I18n.t('request_response.teapot.valid') }
    end

    # POST auth/phone/mfa
    def confirm_phone_registration
      mfa_validity = Authentication::MfaValidator.call(current_user: current_user, params: params, session_mfa_user_id: @token_verifier.user_id)
      if mfa_validity.failure?
        redirect_to RailsBase.url_routes.authenticated_root_path, alert: I18n.t('authentication.confirm_phone_registration.fail', message: mfa_validity.message)
        return
      end

      current_user.update!(mfa_enabled: true)

      redirect_to RailsBase.url_routes.authenticated_root_path, notice: I18n.t('authentication.confirm_phone_registration.valid')
    end

    # DELETE auth/phone/disable
    def remove_phone_mfa
      current_user.update!(mfa_enabled: false, last_mfa_login: nil)
      redirect_to RailsBase.url_routes.authenticated_root_path, notice: I18n.t('authentication.remove_phone_mfa')
    end

    # GET auth/email/forgot/:data
    def forgot_password
      result = Authentication::VerifyForgotPassword.call(data: params[:data])

      if result.failure?
        redirect_to result.redirect_url, alert: result.message
        return
      end
      session[:mfa_randomized_token] = result.encrypted_val
      flash[:notice] =
        if @mfa_flow = result.mfa_flow
          I18n.t('authentication.forgot_password.2fa')
        else
          I18n.t('authentication.forgot_password.base')
        end
      @user = result.user
      @data = params[:data]
    end

    # POST auth/email/forgot/:data
    def forgot_password_with_mfa
      return unless validate_token!(purpose: Authentication::Constants::VFP_PURPOSE)

      # datum is expired because it was used with #forgot_password method
      # we dont care, we just want to ensure the correct user (multiple verification ways)
      # -- validate user by datum
      # -- validate user by short lived token
      # -- validate user by mfa_token
      # -- When all match by user and within the lifetime of the short lived token... we b gucci uber super secure/over engineered
      expired_datum = ShortLivedData.get_by_data(data: params[:data], reason: Authentication::Constants::VFP_REASON)

      unless expired_datum
        redirect_to(RailsBase.url_routes.new_user_password_path, alert: I18n.t('authentication.forgot_password_with_mfa.expired_datum'))
        return
      end

      result = Authentication::MfaValidator.call(params: params, session_mfa_user_id: @token_verifier.user_id, current_user: expired_datum.user)
      if result.failure?
        redirect_to(RailsBase.url_routes.new_user_password_path, alert: result.message)
        return
      end

      @mfa_flow = false
      @data = params[:data]
      @user = result.user
      flash[:notice] = I18n.t('authentication.forgot_password_with_mfa.valid_mfa')
      render :forgot_password
    end

    # POST auth/email/reset/:data
    def reset_password
      return unless validate_token!(purpose: Authentication::Constants::VFP_PURPOSE)

      result = Authentication::ModifyPassword.call(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation], data: params[:data], user_id: @token_verifier.user_id, flow: :forgot_password)
      if result.failure?
        redirect_to RailsBase.url_routes.new_user_password_path, alert: result.message
        return
      end

      redirect_to RailsBase.url_routes.authenticated_root_path, notice: I18n.t('authentication.reset_password')
    end

    # GET auth/sso/:data
    def sso_login
      input_params = {
        data: params[:data],
        reason: RailsBase::Authentication::Constants::SSO_LOGIN_REASON
      }
      sso_decision = RailsBase::Authentication::SingleSignOnVerify.call(input_params)
      if sso_decision.failure?
        if current_user.nil?
          flash[:alert] = I18n.t('authentication.sso_login.fail') + sso_decision.message
          redirect_to RailsBase.url_routes.unauthenticated_root_path
          return
        else
          logger.info('User is logged in but failed the SSO login')
        end
      end


      sign_in(sso_decision.user) if current_user.nil?

      url =
        if RailsBase.route_exist?(sso_decision.url_redirect)
          sso_decision.url_redirect
        else
          logger.debug("Failed to find #{sso_decision.url_redirect}. Redirecing to root")
          RailsBase.url_routes.authenticated_root_path
        end

      flash[:notice] = I18n.t('authentication.sso_login.valid')
      redirect_to url
    end

    private

    def json_validate_current_user!
      return if current_user

      render json: { error: "Unauthorized" }.to_json, :status => 401
      return false
    end

    def validate_token!(purpose: Authentication::Constants::MSET_PURPOSE)
      @token_verifier =
        Authentication::SessionTokenVerifier.call(purpose: purpose, mfa_randomized_token: session[:mfa_randomized_token])
      return true if @token_verifier.success?

      redirect_to RailsBase.url_routes.new_user_session_path, alert: @token_verifier.message
      return false
    end
  end
end
