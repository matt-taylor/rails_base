require 'rails_base/admin/index_tile'

# ID Tile
params = {
  type: :plain,
  value: ->(user) { user.id },
  insert: 0, # optional value default is to push it to the end of the array ORDER MATTERS
  name: 'user_id', # name to be amended to html id
  col_name: 'User Id', # Expected to be the column header name
}

instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)

# Name Tile
params = {
  type: :text,
  value: ->(user) { user.full_name },
  insert: 1, # optional value default is to push it to the end of the array ORDER MATTERS
  name: 'full_name', # name to be amended to html id
  col_name: 'Full Name', # Expected to be the column header name
  partial: 'rails_base/shared/admin_modify_name',
  min_width: 220,
  disabled: -> (user, admin_user) { !RailsBase.config.admin.name_tile_users.call(admin_user) },
  disabled_msg: -> (user, admin_user) { 'Your admin user does not have permissions' }
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)

# Active Tile
params = {
  type: :toggle,
  value: ->(user) { user.active },
  on: 'Active',
  off: 'Inactive',
  name: 'active', # name to be amended to html id
  col_name: 'Active User', # Expected to be the column header name
  disabled: -> (user, admin_user) { user == admin_user || !RailsBase.config.admin.email_tile_users.call(admin_user) },
  disabled_msg: -> (user, admin_user) { 'Your admin user does not have permissions' }
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)

# Email Tile
params = {
  type: :risky,
  value: ->(user) { user.email },
  insert: 2, # optional value default is to push it to the end of the array ORDER MATTERS
  name: :email, # name to be amended to html id
  col_name: 'Email', # Expected to be the column header name
  min_width: 220,
  disabled: -> (user, admin_user) { !RailsBase.config.admin.email_validate_tile_users.call(admin_user) },
  disabled_msg: -> (user, admin_user) { 'Your admin user does not have permissions' }
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)

# Email Validated Tile
params = {
  type: :toggle,
  value: ->(user) { user.email_validated },
  on: 'Valid',
  off: 'Invalid',
  name: 'email_validated', # name to be amended to html id
  col_name: 'Email Validated?', # Expected to be the column header name
  disabled: -> (user, admin_user) { !RailsBase.config.admin.email_tile_users.call(admin_user) },
  disabled_msg: -> (user, admin_user) { 'Your admin user does not have permissions' }
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)

# phone_number Tile
params = {
  type: :risky,
  value: ->(user) { user.phone_number },
  name: :phone_number, # name to be amended to html id
  col_name: 'Phone Number', # Expected to be the column header name
  min_width: 180,
  disabled: -> (user, admin_user) { !RailsBase.config.admin.phone_tile_users.call(admin_user) },
  disabled_msg: -> (user, admin_user) { 'Your admin user does not have permissions' }

}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)

# Mfa Enabled Validated Tile
params = {
  type: :toggle,
  value: ->(user) { user.mfa_enabled },
  on: 'Enabled',
  off: 'Disabled',
  name: 'mfa_enabled', # name to be amended to html id
  col_name: 'MFA Enabled?', # Expected to be the column header name
  disabled: -> (user, admin_user) { !RailsBase.config.admin.mfa_tile_users.call(admin_user) },
  disabled_msg: -> (user, admin_user) { 'Your admin user does not have permissions' },
  min_width: 220,
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)


# Admin Type Tile
params = {
  type: :selector,
  value: ->(user) { user.admin },
  name: 'admin', # name to be amended to html id
  col_name: 'Admin Type', # Expected to be the column header name
  selector: -> (user) { RailsBase.config.admin.admin_types },
  disabled: -> (user, admin_user) { user == admin_user || !RailsBase.config.admin.admin_type_tile_users.call(admin_user) },
  disabled_msg: -> (user, admin_user) { 'Unable to complete action.' }
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)


selector_array = Proc.new do |user|
  base = [RailsBase.config.user.class::USER_DEFINED_KEY, RailsBase.config.user.class::USER_DEFINED_ZONE[RailsBase.config.user.class::USER_DEFINED_KEY].call(user)]
  RailsBase.config.user.class::ACTIVE_SUPPORT_MAPPING.each do |k,v|
    base << [k, v.call]
  end
  base
end
# Users Timezone
params = {
  type: :selector,
  value: ->(user) { user.last_known_timezone },
  name: 'last_known_timezone', # name to be amended to html id
  col_name: 'Timezone', # Expected to be the column header name
  selector: -> (user) { selector_array.call(user) },
  disabled: -> (user, admin_user) { !RailsBase.config.admin.modify_timezone_tile_users.call(admin_user) },
  disabled_msg: -> (user, admin_user) { 'Unable to complete action.' }
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)

# Last logged in
params = {
  type: :plain,
  value: ->(user) { user.last_sign_in_at || 'Never' },
  name: 'logged_in_last', # name to be amended to html id
  col_name: 'Last Logged In', # Expected to be the column header name
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)


# Impersonation Tile
params = {
  type: :button,
  value: ->(_user) { },
  name: 'impersonate', # name to be amended to html id
  col_name: 'Impersonate', # Expected to be the column header name
  method: :post,
  color: 'warning',
  disabled: ->(user, admin_user) { !RailsBase.config.admin.impersonate_tile_users.call(admin_user) },
  disabled_msg: ->(user, admin_user) { 'Your Admin User is not permitted to impersonate Users' },
  url: ->(user) { RailsBase.url_routes.switch_user_path(scope_identifier: "user_#{user.id}") }
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)

# SSO send Tile
params = {
  type: :button,
  value: ->(_user) { },
  name: 'sso_send', # name to be amended to html id
  col_name: 'Send SSO', # Expected to be the column header name
  method: :post,
  color: 'warning',
  disabled: ->(user, admin_user) { !RailsBase.config.admin.sso_tile_users.call(admin_user) },
  disabled_msg: ->(user, admin_user) { 'Your Admin User is not permitted to send SSO' },
  url: ->(user) { RailsBase.url_routes.admin_sso_send_path(id: user.id) }
}
instance = RailsBase::Admin::IndexTile.new(**params)
RailsBase::Admin::IndexTile.add(instance)
