module RailsBase
  class AdminController < ApplicationController
    before_action :authenticate_user!
    before_action :validate_token!, only: [:update_email, :update_phone]
    skip_before_action :admin_reset_impersonation_session!

    include AdminHelper

    # GET admin/impersonate/:scope_identifier
    def index

    end

    # POST admin/update
    def update_attribute
      update = RailsBase::AdminUpdateAttribute.call(params: params)
      if update.success?
        render json: { success: true, message: update.message, attribute: update.attribute }
      else
        render json: { success: false, message: update.message }, status: 404
      end
    end

    def update_name
      user = User.find(params[:id])

      result = NameChange.call(
        first_name: params[:first_name],
        last_name: params[:last_name],
        current_user: user,
        admin_user_id: accurate_admin_user
      )

      if result.success?
        msg = "Successfully changed name from [#{result.original_name}] to [#{result.name_change}]"
        render json: { success: true, message: msg, full_name: result.name_change }
      else
        render json: { success: false, message: "Failed to change #{user.id} name" }, status: 404
      end
    end

    def update_email
      user = User.find(params[:id])
      result = EmailChange.call(email: params[:email], user: user)
      if result.success?
        msg = "Successfully changed email from [#{result.original_email}] to [#{result.new_email}]"
        render json: { success: true, message: msg, email: result.new_email }
      else
        render json: { success: false, message: result.message }, status: 404
      end
    end

    def update_phone
      begin
        params[:value] = params[:phone_number].gsub(/\D/,'')
      rescue
        params[:value] = ''
        params[:_fail_] = true
      end
      params[:attribute] = :phone_number
      update_attribute
    end

    # POST admin/validate_intent/send
    def send_2fa
      reason = "#{SESSION_REASON_BASE}-#{SecureRandom.uuid}"
      result = AdminRiskyMfaSend.call(user: admin_user, reason: reason)
      if result.success?
        session[SESSION_REASON_KEY] = reason
        render json: { success: true, message: result.message }
      else
        render json: { success: false, message: result.message }, status: 404
      end
    end

    # POST admin/validate_intent/verify
    def verify_2fa
      params = {
        session_mfa_user_id: admin_user.id,
        current_user: admin_user,
        input_reason: session_reason,
        params: parse_mfa_to_obj
      }
      result = RailsBase::Authentication::MfaValidator.call(params)
      encrypt = RailsBase::Authentication::MfaSetEncryptToken.call(user: admin_user, purpose: session_reason, expires_at: 1.minute.from_now)
      if result.success?
        session[:mfa_randomized_token] = encrypt.encrypted_val
        render json: { success: true, message: result.message }
      else
        render json: { success: false, message: result.message }, status: 404
      end
    end

    # POST admin/impersonate
    def switch_back
      unless original_user_id = session[RailsBase::Authentication::Constants::ADMIN_REMEMBER_USERID_KEY]
        # something wonky happend to the session. Kick user back to homepage and relogin
        warden.logout(:user)
        flash[:alert] = 'Unknown failure. Please log in again'
        redirect_to RailsBase.url_routes.unauthenticated_root_path
        session.clear
        return
      end

      # use warden here so that we dont add to devise signin/out hooks
      warden.set_user(User.find(original_user_id), scope: :user)

      # Critical step to ensure subsequent apps dont think we are an impersonation
      session.delete(RailsBase::Authentication::Constants::ADMIN_REMEMBER_REASON)

      flash[:notice] = 'You no longer have an identity crisis. You are back to normal.'
      redirect_to RailsBase.url_routes.admin_base_path
    end

    private

    def validate_token!
      @token_verifier =
        RailsBase::Authentication::SessionTokenVerifier.call(mfa_randomized_token: session[:mfa_randomized_token], purpose: session_reason)
      return if @token_verifier.success?

      render json: { success: false, message: 'Authorization token has expired or not present. Try again' }, status: 403
      return false
    end
  end
end
