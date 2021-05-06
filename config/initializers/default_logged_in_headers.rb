params = {
  title: 'Admin',
  url: -> {  Rails.application.routes.url_helpers.admin_base_path },
  type: LinkDecisionHelper::NAVBAR_LOGGED_IN,
  display: ->(current_user) { RailsBase.config.admin.view_admin_page?(current_user) }
}
LinkDecisionHelper.new(**params).assign!

params = {
  title: 'Admin History',
  url: -> {  Rails.application.routes.url_helpers.admin_history_path },
  display: -> (current_user) { RailsBase.config.admin.enable_history_by_user?(current_user) } ,
  type: LinkDecisionHelper::NAVBAR_LOGGED_IN,
}
LinkDecisionHelper.new(**params).assign!

params = {
  title: 'Admin Config',
  url: -> {  Rails.application.routes.url_helpers.admin_config_path },
  display: -> (current_user) { RailsBase.config.admin.config_page?(current_user) } ,
  type: LinkDecisionHelper::NAVBAR_LOGGED_IN,
}
LinkDecisionHelper.new(**params).assign!

params = {
  title: 'Sidekiq',
  url: -> {  Rails.application.routes.url_helpers.sidekiq_web_path },
  display: -> (current_user) { RailsBase.config.sidekiq.view_ui?(current_user) } ,
  type: LinkDecisionHelper::NAVBAR_LOGGED_IN,
  _blank: true,
}
LinkDecisionHelper.new(**params).assign!
