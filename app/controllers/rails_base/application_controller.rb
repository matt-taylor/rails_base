module RailsBase
  class ApplicationController < ActionController::Base
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :is_timeout_error?
    include ApplicationHelper

    def is_timeout_error?
      return if current_user || !params.keys.include?('timeout')

      flash[:notice] = nil
      flash[:alert] = 'Your session expired. Please sign in again to continue.'
    end

    protected

    def configure_permitted_parameters
      added_attrs = [:phone_number, :email, :password, :password_confirmation, :remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :account_update, keys: added_attrs
    end
  end
end
