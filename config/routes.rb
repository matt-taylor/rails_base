Rails.application.routes.draw do
  ##################################
  # Start of error handling routes #
  ##################################

  get '/404', to: 'rails_base/errors#not_found', as: :error_404
  get '/422', to: 'rails_base/errors#unacceptable', as: :error_422
  get '/500', to: 'rails_base/errors#internal_error', as: :error_500

  ################################
  # End of error handling routes #
  ################################

  ################################
  # Start of UserSettings routes #
  ################################

  get 'user/settings', to: 'rails_base/user_settings#index', as: :user_settings
  post 'user/settings/edit/name', to: 'rails_base/user_settings#edit_name', as: :user_edit_name
  post 'user/settings/edit/password', to: 'rails_base/user_settings#edit_password', as: :edit_password
  post 'user/settings/confirm/password/:reason', to: 'rails_base/user_settings#confirm_password', as: :confirm_current_password
  post 'user/settings/destroy', to: 'rails_base/user_settings#destroy_user', as: :destroy_user

  ##############################
  # End of UserSettings routes #
  ##############################

  ##################################
  # Start of Authentication routes #
  ##################################

  # START ROOT PATH AUTHENTICATED -- This is devise magic methods
  unless (Rails.application.routes.url_helpers.authenticated_root_path rescue false)
    authenticated do
      root to: 'rails_base/user_settings#index', as: :authenticated_root
    end
  end
  # END ROOT PATH AUTHENTICATED

  devise_for :users, controllers:
    {
      sessions: 'rails_base/users/sessions',
      registrations: 'rails_base/users/registrations',
      passwords: 'rails_base/users/passwords'
    }

  devise_scope :user do
    delete '/signout', to: 'devise/sessions#destroy', as: :signout
    get 'heartbeat', to: 'rails_base/users/sessions#hearbeat_without_auth', as: :heartbeat_without_auth
    post 'heartbeat', to: 'rails_base/users/sessions#hearbeat_with_auth', as: :heartbeat_with_auth

    # START ROOT PATH UNAUTHENTICATED
    unless (Rails.application.routes.url_helpers.unauthenticated_root_path rescue false)
      unauthenticated do
        root to: 'rails_base/users/sessions#new', as: :unauthenticated_root
      end
    end
    # END ROOT PATH UNAUTHENTICATED
  end

  get 'auth/validate/:data', to: 'rails_base/secondary_authentication#sso_login', as: :sso_login
  get 'auth/email/wait', to: 'rails_base/secondary_authentication#static', as: :auth_static
  get 'auth/email/:data', to: 'rails_base/secondary_authentication#email_verification', as: :email_verification
  get 'auth/login', to: 'rails_base/secondary_authentication#after_email_login_session_new', as: :login_after_email
  post 'auth/login', to: 'rails_base/secondary_authentication#after_email_login_session_create', as: :login_after_email_session_create
  post 'auth/resend_email', to: 'rails_base/secondary_authentication#resend_email', as: :resend_email_verification
  delete 'auth/phone/mfa', to: 'rails_base/secondary_authentication#remove_phone_mfa', as: :remove_phone_registration_mfa
  get 'auth/password/forgot/:data', to: 'rails_base/secondary_authentication#forgot_password', as: :forgot_password_auth
  post 'auth/password/forgot/:data', to: 'rails_base/secondary_authentication#forgot_password_with_mfa', as: :forgot_password_with_mfa_auth
  post 'auth/password/reset/:data', to: 'rails_base/secondary_authentication#reset_password', as: :reset_password_auth

  constraints(->(_req) { RailsBase.config.mfa.enable? }) do
    get 'mfa_verify', to: 'rails_base/mfa_auth#mfa_code', as: :mfa_code
    post 'mfa_verify', to: 'rails_base/mfa_auth#mfa_code_verify', as: :mfa_code_verify
    post 'resend_mfa', to: 'rails_base/mfa_auth#resend_mfa', as: :resend_mfa

    post 'auth/phone', to: 'rails_base/secondary_authentication#phone_registration', as: :phone_registration
    post 'auth/phone/mfa', to: 'rails_base/secondary_authentication#confirm_phone_registration', as: :phone_registration_mfa_code

    constraints(->(_req) { RailsBase.config.totp.enable? }) do
      post 'totp', to: 'rails_base/mfa_auth#totp_secret', as: :totp_secret
      post 'totp/validate', to: 'rails_base/mfa_auth#totp_validate', as: :totp_validate
    end
  end

  ################################
  # END of Authentication routes #
  ################################

  #########################
  # Start of Admin routes #
  #########################
  # override url and location for switch_user gem
  constraints(->(_req) { RailsBase.config.admin.enable? }) do
    post 'admin/impersonate/:scope_identifier', to: 'rails_base/switch_user#set_current_user', as: :switch_user

    post 'admin/ack', to: 'rails_base/admin#ack', as: :admin_ack
    post 'admin/impersonate', to: 'rails_base/admin#switch_back', as: :admin_stop_impersonation
    post 'admin/update', to: 'rails_base/admin#update_attribute', as: :admin_upate_attribute
    post 'admin/update/name', to: 'rails_base/admin#update_name', as: :admin_upate_name
    post 'admin/update/email', to: 'rails_base/admin#update_email', as: :admin_upate_email
    post 'admin/update/phone', to: 'rails_base/admin#update_phone', as: :admin_upate_phone
    post 'admin/validate_intent/send', to: 'rails_base/admin#send_2fa', as: :admin_validate_intent
    post 'admin/validate_intent/verify', to: 'rails_base/admin#verify_2fa', as: :admin_verify_intent

    get 'admin', to: 'rails_base/admin#index', as: :admin_base
    get 'admin/config', to: 'rails_base/admin#show_config', as: :admin_config
    get 'admin/history', to: 'rails_base/admin#history', as: :admin_history
    post 'admin/history', to: 'rails_base/admin#history_paginate', as: :admin_history_page

    post 'admin/sso/:id', to: 'rails_base/admin#sso_send', as: :admin_sso_send
  end
  # route is part of admin control, but does not need admin enabled
  get 'auth/sso/:data', to: 'rails_base/admin#sso_retrieve', as: :sso_retrieve

  #######################
  # End of Admin routes #
  #######################
end
