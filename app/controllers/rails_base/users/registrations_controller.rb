# frozen_string_literal: true

class RailsBase::Users::RegistrationsController < Devise::RegistrationsController
  include RailsBase::UserFieldValidators
  before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    # super
    @resource = User.new
    @resource_name = :user
    render template: 'rails_base/devise/registrations/new'
  end

  # POST /users/create
  def create
    # Finds the resource by email and updates tha attributes ... or creates new resource
    resource = (User.find_by_email(params[:user][:email])) || User.new
    if resource.encrypted_password.present?
      @email = params[:user][:email]
      redirect_to RailsBase.url_routes.new_user_session_path, notice: 'Credentials exist. Please login or click forgot Password'
      return
    end

    user_form_validation = validate_complement?(user_params: params[:user])

    unless user_form_validation[:status]
      resource.assign_attributes(sign_up_params.except(:password, :password_confirmation))
      @resource = resource
      @resource_name = resource_name
      @alert_errors = user_form_validation[:errors]
      flash[:error] = @alert_errors.values.join('</br>')
      render :new, notice: "Failure shit"
      return
    end

    resource.admin = RailsBase.config.admin.default_admin_type
    resource.assign_attributes(sign_up_params)

    if resource.save
      resource.reload
      sign_up(resource_name, resource)
      sign_out(resource)

      email_verification = RailsBase::Authentication::SendVerificationEmail.call(user: resource, reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON)
      if email_verification.failure?
        redirect_to RailsBase.url_routes.new_user_session_path, alert: email_verification.message
        return
      end
      session[:mfa_randomized_token] = nil
      session[:mfa_randomized_token] =
        RailsBase::Authentication::MfaSetEncryptToken.call(purpose: RailsBase::Authentication::Constants::SSOVE_PURPOSE, user: resource, expires_at: Time.zone.now + 20.minutes).encrypted_val
      redirect_to RailsBase.url_routes.auth_static_path, notice: "Check email for verification email."
    else
      flash[:error] = resource.errors.messages
      email = params[:email] if !resource.errors.details.keys.include?(:email)
      @resource = resource
      @resource_name = resource_name
      render :new, notice: 'Unknown failure. Please try again'
    end
  end

  # GET /resource/edit
  def edit
    raise
  end

  # PUT /resource
  def update
    raise
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
  end
end
