module RailsBase
  class AdminController < ApplicationController
    before_action :authenticate_user!
    before_action :validate_token!, only: [:update_email, :update_phone]
    skip_before_action :admin_reset_impersonation_session!

    include AdminHelper

    # GET admin/impersonate/:scope_identifier
    def index
    end

    # POST admin/ack
    def ack
      success = true
      begin
        time = Time.at params[:time].to_i
        RailsBase::Admin::ActionCache.instance.delete_actions_since!(user: current_user, time: time)
        RailsBase::Admin::ActionCache.instance.update_last_viewed(user: current_user, time: time)
      rescue StandardError => e
        logger.error(e.message)
        logger.error('Failed to acknowledge users admion actions')
        success = false
      end
      if success
        render json: { success: true }
      else
        render json: { success: false }, status: 500
      end
    end

    # GET admin/history
    def history
      @starting_admin = paginate_get_admins_array.last
      @starting_user = paginate_get_users_array.last
      session[:rails_base_paginate_start_user] = @starting_user[1]
      session[:rails_base_paginate_start_admin] = @starting_admin[1]
      @starting_page = 1
      @count_on_page = AdminAction::DEFAULT_PAGE_COUNT
    end

    # POST admin/history
    def history_paginate
      @starting_admin = paginate_get_admins_array.find { |u| u[1] == params[:admin].to_i } || paginate_get_admins_array.last
      @starting_user = paginate_get_users_array.find { |u| u[1] == params[:user].to_i } || paginate_get_users_array.last

      @starting_page = paginate_admin_what_page
      @count_on_page = params[:pagination_count].to_i

      if paginate_diff_id?(type: :admin) || paginate_diff_id?(type: :user)
        logger.warn "Admin or User has been selected. paginating from first page"
        @starting_page = 1
      end

      session[:rails_base_paginate_start_user] = @starting_user[1]
      session[:rails_base_paginate_start_admin] = @starting_admin[1]
      begin
        html = render_to_string(partial: 'rails_base/shared/admin_history')
      rescue StandardError => e
        logger.error(e.message)
        logger.error('Failed to render html for history')
        html
      end

      if html
        render json: { success: true, html: html, per_page: @count_on_page, page: @starting_page }
      else
        render json: { success: false }, status: 500
      end
    end

    # POST admin/update
    def update_attribute
      update = RailsBase::AdminUpdateAttribute.call(params: params)
      if update.success?
        @_admin_action_struct = RailsBase::AdminStruct.new(update.original_attribute, update.attribute, update.model)
        render json: { success: true, message: update.message, attribute: update.attribute }
      else
        @_admin_action_struct = false
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
        @_admin_action_struct = RailsBase::AdminStruct.new(result.original_name, result.name_change, user)
        msg = "Successfully changed name from [#{result.original_name}] to [#{result.name_change}]"
        render json: { success: true, message: msg, full_name: result.name_change }
      else
        @_admin_action_struct = false
        render json: { success: false, message: "Failed to change #{user.id} name" }, status: 404
      end
    end

    def update_email
      user = User.find(params[:id])
      result = EmailChange.call(email: params[:email], user: user)
      if result.success?
        @_admin_action_struct = RailsBase::AdminStruct.new(result.original_email, result.new_email, user)
        msg = "Successfully changed email from [#{result.original_email}] to [#{result.new_email}]"
        render json: { success: true, message: msg, email: result.new_email }
      else
        @_admin_action_struct = false
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
      unless modify_id = params[:modify_id]
        logger.warn("Failed to find #{@modify_id} in payload")
        render json: { success: false, message: 'Hmm. Something fishy happend. Failed to find text to modify' }, status: 404
        return
      end

      unless render_partial = SECOND_MODAL_MAPPING[params[:modal_mapping].to_sym] rescue nil
        logger.warn("Mapping [#{params[:modal_mapping]}] is not defined. Expected part of #{SECOND_MODAL_MAPPING.keys}")
        render json: { success: false, message: 'Hmm. Something fishy happend. Failed to find modal mapping' }, status: 404
        return
      end

      unless user = User.find(params[:id]) rescue nil
        logger.warn("Failed to find id:[#{params[:id]}] ")
        render json: { success: false, message: 'Hmm. Something fishy happend. Failed to find associated id' }, status: 404
        return
      end

      params = {
        session_mfa_user_id: admin_user.id,
        current_user: admin_user,
        input_reason: session_reason,
        params: parse_mfa_to_obj
      }
      result = RailsBase::Authentication::MfaValidator.call(params)
      encrypt = RailsBase::Authentication::MfaSetEncryptToken.call(user: admin_user, purpose: session_reason, expires_at: 1.minute.from_now)

      begin
        html = render_to_string(partial: render_partial, locals: { user: user, modify_id: modify_id })
      rescue StandardError => e
        logger.warn("#{e.message}")
        logger.warn("Failed to render html correctly")
        html = nil
      end
      if html.nil?
        logger.warn("Failed to find render html correctly")
        render json: { success: false, message: 'Apologies. Wee are struggling to render the page. Please try again later' }, status: 500
        return
      end

      if result.success?
        session[:mfa_randomized_token] = encrypt.encrypted_val
        render json: { success: true, message: result.message, html: html }
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
