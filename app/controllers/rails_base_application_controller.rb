class RailsBaseApplicationController < ActionController::Base
  layout 'rails_base/application'

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_time_zone
  before_action :is_timeout_error?
  before_action :admin_reset_impersonation_session!
  before_action :footer_mode_case
  after_action :clear_expired_mfa_events_from_session!

  before_action :populate_admin_actions, if: -> { RailsBase.config.admin.enable_actions? }
  after_action :capture_admin_action

  include RailsBase::ApplicationHelper
  helper_method :mfa_fallback?, :is_safari?, :is_mobile?

  include RailsBase::AppearanceHelper
  helper_method :appearance_text_class, :footer_mode_case, :appearance_mode_drop_down, :appearance_text_class

  include RailsBase::CaptureReferenceHelper

  def set_time_zone
    return unless RailsBase.config.user.tz_user_defined?
    return if current_user.nil?

    # esape this since this is not signed
    offset = cookies[TIMEZONE_OFFSET_COOKIE].to_i

    cookie_tz = ActiveSupport::TimeZone[((offset * -1) / 60.0)]

    if session_tz = session[TIMEZONE_SESSION_NAME]
      # if session exists
      if cookie_tz && session_tz != cookie_tz.name
        # if cookie exists and cookie_tz does not match, update db and session
        current_user.update_tz(tz_name: cookie_tz.name)
        session[TIMEZONE_SESSION_NAME] = cookie_tz.name
      end
    else
      # if session timezone does not exist, attempt to push to DB and set to session
      current_user.update_tz(tz_name: cookie_tz.name)
      session[TIMEZONE_SESSION_NAME] = cookie_tz.name
    end
    Thread.current[TIMEZONE_THREAD_NAME] = session[TIMEZONE_SESSION_NAME]
  end

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

  def add_mfa_event_to_session(event:)
    unless RailsBase::MfaEvent === event
      logger.error("Failed to add MFA event to session. Unexpected event passed")
      return false
    end

    session[:"__#{RailsBase.app_name}_mfa_events"] ||= {}
    # nested hashes in the session are string keys -- ensure it gets converted to a string during assignment to avoid confusion
    session[:"__#{RailsBase.app_name}_mfa_events"][event.event.to_s] = event.to_hash.to_json
  end

  def clear_mfa_event_from_session!(event_name:)
    session[:"__#{RailsBase.app_name}_mfa_events"] ||= {}
    session[:"__#{RailsBase.app_name}_mfa_events"].delete(event_name.to_s)

    true
  end

  def clear_expired_mfa_events_from_session!
    mfa_events = session.delete(:"__#{RailsBase.app_name}_mfa_events")
    return true if mfa_events.nil?

    mfa_events.each do |event_name, metadata|
      event_object = RailsBase::MfaEvent.new(**JSON.parse(metadata).deep_symbolize_keys)
      if event_object.valid_by_death_time?
        add_mfa_event_to_session(event: event_object)
      else
        logger.warn("MFA event: [#{event_name}] is no longer valid. Ejecting from session ")
      end

    end
  rescue => e
    logger.error("Oh know! We may have just removed all MFA events. Re-Auth is now required")
    true
  end

  def validate_mfa_with_event_json!(mfa_event_name: params[:mfa_event])
    return true if soft_mfa_with_event(mfa_event_name:)

    render json: { error: "Unauthorized. Incorrect Event" }.to_json, :status => 401
    false
  end

  def validate_mfa_with_event!(mfa_event_name: params[:mfa_event])
    return true if soft_mfa_with_event(mfa_event_name:)

    redirect = @__rails_base_mfa_event&.invalid_redirect || RailsBase.url_routes.unauthenticated_root_path
    redirect_to(redirect, alert: @__rails_base_mfa_event_invalid_reason)
    false
  end

  def soft_mfa_with_event(mfa_event_name: params[:mfa_event])
    # nested hashes in the session are string keys -- ensure it gets converted to a string during lookup
    mfa_event = session.dig(:"__#{RailsBase.app_name}_mfa_events", mfa_event_name.to_s)
    if mfa_event.nil?
      @__rails_base_mfa_event_invalid_reason = "Unauthorized MFA event"
      return false
    end
    @__rails_base_mfa_event = RailsBase::MfaEvent.new(**JSON.parse(mfa_event).deep_symbolize_keys)

    if @__rails_base_mfa_event.valid?
      @__rails_base_mfa_event.increase_access_count!
      return true
    end
    @__rails_base_mfa_event_invalid_reason = "MFA event for #{mfa_event_name} is invalid. #{@__rails_base_mfa_event.event}"

    false
  end

  def json_validate_current_user!
    return if current_user

    render json: { error: "Unauthorized" }.to_json, :status => 401
    return false
  end

  def validate_mfa_token!(purpose: RailsBase::Authentication::Constants::MSET_PURPOSE)
    return true if soft_validate_mfa_token(token: session[:mfa_randomized_token], purpose: purpose)

    if user_signed_in?
      redirect_to RailsBase.url_routes.user_settings_path, alert: @token_verifier.message
    else
      redirect_to RailsBase.url_routes.new_user_session_path, alert: @token_verifier.message
    end
    return false
  end

  def soft_validate_mfa_token(token:, purpose: RailsBase::Authentication::Constants::MSET_PURPOSE)
    @token_verifier =
      RailsBase::Authentication::SessionTokenVerifier.call(purpose: purpose, mfa_randomized_token: token)

    @token_verifier.success?
  end

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
      encrpytion = RailsBase::Mfa::EncryptToken.call(params)
      session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_REASON] = encrpytion.encrypted_val
    end
  end

  def configure_permitted_parameters
    added_attrs = [:phone_number, :email, :password, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end
end
