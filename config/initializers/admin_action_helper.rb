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
RailsBase::Admin::ActionHelper.new(params).add!


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
RailsBase::Admin::ActionHelper.new(params).add!


params = {
  proc: nil,
  title: 'Removed Phone from account',
  controller: RailsBase::SecondaryAuthenticationController,
  action: 'remove_phone_mfa',
  default: true
}
RailsBase::Admin::ActionHelper.new(params).add!

params = {
  proc: nil,
  title: 'Setting Phone on account',
  controller: RailsBase::SecondaryAuthenticationController,
  action: 'phone_registration',
  default: true
}
RailsBase::Admin::ActionHelper.new(params).add!

params = {
  proc: nil,
  title: 'Impersonation',
  controller: RailsBase::SwitchUserController,
  action: 'set_current_user',
  default: true
}
RailsBase::Admin::ActionHelper.new(params).add!
