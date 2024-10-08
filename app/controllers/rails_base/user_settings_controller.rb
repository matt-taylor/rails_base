module RailsBase
  class UserSettingsController < RailsBaseApplicationController
    before_action :authenticate_user!
    before_action :confirm_password_flow, only: :confirm_password

    include RailsBase::UserSettingsHelper

    # GET user/settings
    def index
      @type = :rest
      @endpoint = RailsBase.url_routes.totp_register_validate_path

      if current_user.mfa_sms_enabled
        clear_mfa_event_from_session!(event_name: RailsBase::MfaEvent::ENABLE_SMS_EVENT)
        add_mfa_event_to_session(event: RailsBase::MfaEvent.sms_disable(user: current_user))
      else
        clear_mfa_event_from_session!(event_name: RailsBase::MfaEvent::DISABLE_SMS_EVENT)
        add_mfa_event_to_session(event: RailsBase::MfaEvent.sms_enable(user: current_user))
      end
    end

    # POST user/settings/edit/name
    def edit_name
      result = NameChange.call(
        first_name: params[:user][:first_name],
        last_name: params[:user][:last_name],
        current_user: current_user,
      )

      if result.failure?
        flash[:alert] = result.message
      else
        @_admin_action_struct = RailsBase::AdminStruct.new(result.original_name, result.name_change)
        flash[:notice] = "Name change succesful to #{result.name_change}"
      end

      redirect_to RailsBase.url_routes.user_settings_path
    end

    # POST user/settings/edit/password
    # expected ajax POST
    def edit_password
      # current user is method and we will loose context if we are succesful in changing password
      # store current user in current context
      user = current_user
      result = RailsBase::Authentication::ModifyPassword.call(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation], current_user: current_user, flow: :user_settings)

      if result.failure?
        redirect_to RailsBase.url_routes.user_settings_path, alert: result.message
        return
      end

      # password was changed so authentication will fail. Re-signin user
      sign_out(current_user)
      sign_in(user.reload)
      redirect_to RailsBase.url_routes.user_settings_path, notice: 'Succesfully changed password'
    end

    # POST user/settings/confirm/password/:reason
    def confirm_password
      authenticate = RailsBase::Authentication::AuthenticateUser.call(email: current_user.email, current_user: current_user, password: params[:user][:password])

      if authenticate.failure?
        render json: { msg: authenticate.message }, status: 418
      else
        html = render_to_string partial: CONFIRM_PASSWORD_FLOW[params[:reason].to_sym]
        render json: { html: html, datum: datum.data }
      end
    end

    # POST user/settings/destroy
    def destroy_user
      destroy = RailsBase::Authentication::DestroyUser.call(data: params[:data], current_user: current_user)

      if destroy.failure?
        redirect_to RailsBase.url_routes.user_settings_path, alert: destroy.message
      else
        redirect_to RailsBase.url_routes.authenticated_root_path, notice: I18n.t('user_setting.destroy_user.soft')
      end
    end

    private

     def confirm_password_flow
        return true if CONFIRM_PASSWORD_FLOW.keys.include?(params[:reason].to_sym)

        render json: { msg: 'invalid parameter' }, status: 418
        false
     end
  end
end
