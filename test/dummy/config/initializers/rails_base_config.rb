Rails.application.config.to_prepare do
  RailsBase.configure do |config|
    config.owner.max = 3
    config.admin.admin_type_tile_users = ->(user) { user.active && user.at_least_super? }
    config.admin.default_admin_type = :super
  end
end
