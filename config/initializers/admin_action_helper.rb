require 'rails_base/admin/action_helper'

proc = Proc.new do |req, params, admin_user, user, title, struct|
  actions_mapping = {
    index: 'Viewed Settings page',
    edit_name: 'Modified name',
    edit_password: 'Modified Password',
    destroy_user: '!Destroyed User!'
  }

  if actions_mapping.keys.include?(params[:action].to_sym)
    {
      admin_user: admin_user,
      user: user,
      action: actions_mapping[params[:action].to_sym] ,
      original_attribute: struct&.original_attribute,
      new_attribute: struct&.new_attribute
    }
  else
    nil
  end
end
# For all User Settings routes
params = {
  proc: proc,
  controller: RailsBase::UserSettingsController,
  default: true
}
RailsBase::Admin::ActionHelper.new(**params).add!


proc = Proc.new do |req, params, admin_user, user, title, struct|
  actions_mapping = {
    update_attribute: "Updated [#{params[:attribute]}]",
    update_name: 'Updated Name',
    update_email: 'Updated Email',
    update_phone: 'Updated Phone number',
    index: 'Viewed Admin Index',
    sso_send: 'Sent SSO to user'
  }

  if actions_mapping.keys.include?(params[:action].to_sym)
    {
      admin_user: admin_user,
      user: struct&.user,
      action: actions_mapping[params[:action].to_sym],
      original_attribute: struct&.original_attribute,
      new_attribute: struct&.new_attribute
    }
  else
    nil
  end
end
# For all Admin  routes
params = {
  proc: proc,
  controller: RailsBase::AdminController,
  default: true
}
RailsBase::Admin::ActionHelper.new(**params).add!

proc = Proc.new do |req, params, admin_user, user, title, struct|
  actions_mapping = {
    sms_registration: 'MFA Attempt to Register new SMS number',
    sms_confirmation: 'MFA Confirm new SMS number',
    sms_removal: 'MFA SMS removed',
  }

  if actions_mapping.keys.include?(params[:action].to_sym)
    {
      admin_user: admin_user,
      user: user,
      action: actions_mapping[params[:action].to_sym] ,
      original_attribute: struct&.original_attribute,
      new_attribute: struct&.new_attribute
    }
  else
    nil
  end
end
# All SMS register actions
params = {
  proc: proc,
  controller: RailsBase::Mfa::Register::SmsController,
  default: true
}
RailsBase::Admin::ActionHelper.new(**params).add!


proc = Proc.new do |req, params, admin_user, user, title, struct|
  actions_mapping = {
    totp_remove: 'MFA TOTP remove',
    totp_secret: 'MFA TOTP Attempt to add new Authenticator',
    totp_validate: 'MFA TOTP Authenticator added',
  }

  if actions_mapping.keys.include?(params[:action].to_sym)
    {
      admin_user: admin_user,
      user: user,
      action: actions_mapping[params[:action].to_sym] ,
      original_attribute: struct&.original_attribute,
      new_attribute: struct&.new_attribute
    }
  else
    nil
  end
end
# All TOTP register actions
params = {
  proc: proc,
  controller: RailsBase::Mfa::Register::TotpController,
  default: true
}
RailsBase::Admin::ActionHelper.new(**params).add!

params = {
  proc: nil,
  title: 'Impersonation',
  controller: RailsBase::SwitchUserController,
  action: 'set_current_user',
  default: true
}
RailsBase::Admin::ActionHelper.new(**params).add!
