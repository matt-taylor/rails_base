module RailsBase
  class SecondaryAuthenticationController < RailsBaseApplicationController
    before_action :authenticate_user!, only: [:remove_phone_mfa, :confirm_phone_registration]

    before_action :validate_mfa_token!, only: [:resend_email, :wait, :confirm_phone_registration]

    # GET auth/wait
    def static
      return unless validate_mfa_token!(purpose: Authentication::Constants::SSOVE_PURPOSE)

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
      return unless validate_mfa_token!(purpose: Authentication::Constants::SSOVE_PURPOSE)

      @user = User.new
      if flash[:alert].nil? && flash[:notice].nil?
        flash[:notice] = I18n.t('authentication.after_email_login_session_new')
      end
    end

    # POST auth/login
    def after_email_login_session_create
      return unless validate_mfa_token!(purpose: Authentication::Constants::SSOVE_PURPOSE)

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

    # GET auth/email/forgot/:data
    def forgot_password
      result = Authentication::VerifyForgotPassword.call(data: params[:data])

      if result.failure?
        redirect_to result.redirect_url, alert: result.message
        return
      end

      event = RailsBase::MfaEvent.forgot_password(user: result.user, data: params[:data])
      if result.mfa_flow
        flash[:notice] = "MFA required to reset password"
        redirect_to(RailsBase.url_routes.mfa_with_event_path(mfa_event: event.event))
      else
        # Requirements to continue were satiatet..we can let the user reset their password
        event.satiated!
        flash[:notice] = "Datum valid. Reset your password"
        redirect_to(RailsBase.url_routes.reset_password_input_path(data: params[:data]))
      end

      # Upload event to the session as a last step to ensure we capture if it was satiated or not
      add_mfa_event_to_session(event:)
    end

    # GET auth/password/reset/:data
    def reset_password_input
      return unless validate_mfa_with_event!(mfa_event_name: RailsBase::MfaEvent::FORGOT_PASSWORD)

      if @__rails_base_mfa_event.satiated?
        @data = params[:data]
        @user = User.find(@__rails_base_mfa_event.user_id)
      else
        logger.error("MFA Event was not satiated. Kicking user back to root")
        clear_mfa_event_from_session!(event_name: @__rails_base_mfa_event.event)
        flash[:alert] = "Unauthorized access"
        session.clear
        redirect_to(RailsBase.url_routes.unauthenticated_root_path)
      end
    end

    # POST auth/email/reset/:data
    def reset_password
      return unless validate_mfa_with_event!(mfa_event_name: RailsBase::MfaEvent::FORGOT_PASSWORD)

      unless @__rails_base_mfa_event.satiated?
        logger.error("MFA Event was not satiated. Kicking user back to root")
        clear_mfa_event_from_session!(event_name: @__rails_base_mfa_event.event)
        flash[:alert] = "Unauthorized access"
        session.clear
        redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        return
      end
      result = Authentication::ModifyPassword.call(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation], data: params[:data], user_id: @__rails_base_mfa_event.user_id, flow: :forgot_password)
      if result.failure?
        redirect_to RailsBase.url_routes.new_user_password_path, alert: result.message
        return
      end

      redirect_to RailsBase.url_routes.authenticated_root_path, notice: I18n.t('authentication.reset_password')
    end

    # GET auth/validate/:data
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
  end
end
