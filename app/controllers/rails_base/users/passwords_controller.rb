# frozen_string_literal: true

class RailsBase::Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  def new
    self.resource = User.new
    render template: 'rails_base/devise/passwords/new'
  end

  # POST /resource/password
  def create
    result = RailsBase::Authentication::SendForgotPassword.call(email: params[:user][:email])
    if result.failure?
      redirect_to RailsBase.url_routes.new_user_password_path, alert: result.message
      return
    end
     redirect_to RailsBase.url_routes.new_user_password_path, notice: result.message
  end
end
