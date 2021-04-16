module RailsBase
  class ApplicationController < ActionController::Base
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :is_timeout_error?
    before_action :admin_reset_impersonation_session!
    before_action :populate_admin_actions, if: -> { RailsBase.config.admin.enable_actions? }

    after_action :capture_admin_action, if: -> { RailsBase.config.admin.enable_actions? }

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
      return if RailsBase.config.admin.view_admin_page?(current_user)

      session.clear
      sign_out(current_user)

      flash[:alert] = 'Unauthorized action. You have been signed out'
      redirect_to RailsBase.url_routes.unauthenticated_root_path
    end

    def populate_admin_actions
      return if session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_REASON].present?
      return if current_user.nil?
      return unless request.fullpath == RailsBase.url_routes.authenticated_root_path

      @__admin_actions_array = AdminAction.get_cache_items(user: current_user, alltime: true)
    end

    def capture_admin_action
      # ToDo: Turn this into a service
      # ToDo: All admin actions come there here: Allow this to be confirugable on or off
      _controller = ActiveSupport::Inflector.camelize("#{params[:controller]}_controller")
      admin_user =
        if _controller == RailsBase::AdminController.to_s
          current_user
        else
          @original_admin_user_id ? User.find(@original_admin_user_id) : nil
        end

      # Means we are not in the admin controller or we are not impersonating
      return if admin_user.nil? || @_admin_action_struct == false

      # Admin action for all routes
      (RailsBase::Admin::ActionHelper.actions.dig(RailsBase::Admin::ActionHelper::ACTIONS_KEY) || []).each do |helper|
        Rails.logger.warn("Admin Action for every action")
        helper.call(req: request, params: params, admin_user: admin_user, user: current_user, struct: @_admin_action_struct)
      end

      # Admin action for all controller routes
      object = RailsBase::Admin::ActionHelper.actions.dig(_controller, RailsBase::Admin::ActionHelper::CONTROLLER_ACTIONS_KEY) || []
      object.each do |helper|
        Rails.logger.warn("Admin Action for #{_controller}")
        helper.call(req: request, params: params, admin_user: admin_user, user: current_user, struct: @_admin_action_struct)
      end

      # Admin action for all controller action specific routes
      (RailsBase::Admin::ActionHelper.actions.dig(_controller, params[:action].to_s) || []).each do |helper|
        Rails.logger.warn("Admin Action for #{_controller}##{params[:action]}")
        helper.call(req: request, params: params, admin_user: admin_user, user: current_user, struct: @_admin_action_struct)
      end
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
