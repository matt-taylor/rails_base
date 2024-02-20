RailsBase.configure do |config|
  config.owner.max = 3
  config.admin.admin_type_tile_users = ->(user) { user.active && user.at_least_super? }
  config.admin.default_admin_type = :super
  config.redis.admin_action_namespace = "rails_base"
end
