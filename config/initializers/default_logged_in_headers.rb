params = {
  title: 'Admin',
  url: -> {  Rails.application.routes.url_helpers.admin_base_path },
  type: LinkDecisionHelper::NAVBAR_LOGGED_IN,
  display: ->(current_user) { RailsBase.config.admin.view_admin_page?(current_user) }
}
LinkDecisionHelper.new(params).assign!


display_proc = Proc.new do |current_user|

end
params = {
  title: 'Admin History',
  url: -> {  Rails.application.routes.url_helpers.admin_history_path },
  display: -> (current_user) { RailsBase.config.admin.enable_history_by_user?(current_user) } ,
  type: LinkDecisionHelper::NAVBAR_LOGGED_IN,
}
LinkDecisionHelper.new(params).assign!
