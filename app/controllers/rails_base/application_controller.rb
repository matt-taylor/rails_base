module RailsBase
  class ApplicationController < ActionController::Base
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :is_timeout_error?
    before_action :admin_reset_impersonation_session!

    include ApplicationHelper

    def is_timeout_error?
      return if current_user || !params.keys.include?('timeout')

      flash[:notice] = nil
      flash[:alert] = 'Your session expired. Please sign in again to continue.'
    end

    def admin_impersonation_session?
      return false if current_user.nil?
      return false unless encrypted_val = session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_REASON].presence

      token = admin_get_token(encrypted_val: encrypted_val)
      if token.failure?
        logger.warn "Failed to parse encrypted token. Either expired or was not present"
        flash[:alert] = 'Failed to retrieve Session token. Retry action'
        redirect_to RailsBase.url_routes.admin_base_path
        return false
      else
        logger.info "Found original_admin_user_id"
        @original_admin_user_id = token.user_id
      end
      true
    end

    def admin_reset_impersonation_session!
      return unless admin_impersonation_session?

      # at this point we know there is an impersonation
      admin_user = User.find @original_admin_user_id
      admin_set_token_on_session(admin_user: admin_user, other_user: current_user)
    end

    def admin_user?
      return if current_user.admin != User::ADMIN_ROLE_TIER_NONE

      session.clear
      sign_out(current_user)

      flash[:alert] = 'Unauthorized action. You have been signed out'
      redirect_to RailsBase.url_routes.unauthenticated_root_path
    end

    protected

    def admin_get_token(encrypted_val:)
      params = {
        mfa_randomized_token: encrypted_val,
        purpose: RailsBase::Authentication::Constants::ADMIN_REMEMBER_REASON,
      }
      RailsBase::Authentication::SessionTokenVerifier.call(params)
    end

    def admin_set_token_on_session(admin_user:, other_user:)
      if admin_user.id !=  other_user.id #dont do this if you are yourself
        logger.warn { "Admin user [#{admin_user.id}] is impersonating user #{other_user.id}" }
        params = {
          user: admin_user,
          purpose: RailsBase::Authentication::Constants::ADMIN_REMEMBER_REASON,
          expires_at: RailsBase::Authentication::Constants::ADMIN_MAX_IDLE_TIME.from_now
        }
        encrpytion = RailsBase::Authentication::MfaSetEncryptToken.call(params)
        session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_REASON] = encrpytion.encrypted_val
      end
    end

    def configure_permitted_parameters
      added_attrs = [:phone_number, :email, :password, :password_confirmation, :remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :account_update, keys: added_attrs
    end
  end
end
