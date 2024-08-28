# frozen_string_literal: true

require 'twilio_helper'

class RailsBase::Users::SessionsController < Devise::SessionsController
  prepend_before_action :protect_heartbeat, only: [:hearbeat_without_auth, :hearbeat_with_auth]
  prepend_before_action :skip_timeout, only: [:hearbeat_without_auth]

  # GET /user/sign_in
  def new
    @user = User.new
    render template: 'rails_base/devise/sessions/new'
  end

  # POST /user/sign_in
  def create
    # Warden/Devise will try to sign the user in before we explicitly do
    # Sign ou the user when this happens so we can sign them back in later
    sign_out(current_user) if current_user

    authenticate = RailsBase::Authentication::AuthenticateUser.call(email: params[:user][:email], password: params[:user][:password])

    if authenticate.failure?
      @user = User.new(email: params[:user][:email])
      flash[:alert] = authenticate.message
      render template: 'rails_base/devise/sessions/new'
      return
    end

    mfa_decision = RailsBase::Authentication::DecisionTwofaType.call(user: authenticate.user)
    if mfa_decision.failure?
      redirect_to RailsBase.url_routes.new_user_session_path, email: params[:user][:email], alert: mfa_decision.message
      return
    end

    if mfa_decision.set_mfa_randomized_token
      session[:mfa_randomized_token] =
        RailsBase::Mfa::EncryptToken.call(
          user: authenticate.user,
          expires_at: mfa_decision.token_ttl,
          purpose: mfa_decision.mfa_purpose,
        ).encrypted_val
    end

    redirect =
      if mfa_decision.sign_in_user
        sign_in(authenticate.user)
        # only referentially redirect when we know the user should sign in
        redirect_from_reference
      end

    redirect ||= mfa_decision.redirect_url

    logger.info { "Successful sign in: Redirecting to #{redirect}" }

    redirect_to(redirect, mfa_decision.flash)
  end

  # DELETE /user/sign_out
  def destroy
    session[:mfa_randomized_token] = nil

    # force the user to sign out
    sign_out(current_user)
    reset_session

    admin_reset_session!

    flash[:notice] = 'You have been succesfully signed out'
    redirect_to RailsBase.url_routes.unauthenticated_root_path
  end

  # GET /heartbeat
  def hearbeat_without_auth
    skip_capture_reference!
    heartbeat
  end

  # POST /heartbeat
  def hearbeat_with_auth
    heartbeat
  end

  private

  def heartbeat
    if current_user
      last_request = session['warden.user.user.session']['last_request_at']
      ttd = last_request + Devise.timeout_in.to_i
      ttl = ttd - Time.zone.now.to_i
      render json: { success: true, ttd: ttd, ttl: ttl, last_request: last_request }
    else
      render json: { success: false }, status: 401
    end
  end

  # ensure session is present before we try and do anything
  # proects the site by not querying for current_user
  # would be better to do this at edge layer
  def protect_heartbeat
    return true if session.keys.present? || browser.bot?

    logger.warn { "Hack attempt. Checking the heartbeat bad user agent. bot?:[#{browser.bot}]" }
    render json: { success: false }, status: 401
  end

  def skip_timeout
    request.env["devise.skip_trackable"] = true
  end
end
