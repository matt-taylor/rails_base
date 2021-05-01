RailsBase.configure do |config|
  config.owner.max = 3
  config.admin.admin_type_tile_users = ->(user) { user.active && user.at_least_super? }
end
