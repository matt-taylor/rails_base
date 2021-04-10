require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Admin < Base
      DEFAULT_VALUES = {
        enable: { type: :boolean, default: true },
        enable_history: {
          type: :boolean,
          default: true,
          dependents: [ -> (i) { i.enable? } ]
        },
        view_admin_page: {
          type: :proc,
          default: ->(user) { user.active && user.admin_super? },
          dependents: [ -> (i) { i.enable? } ]
        },
        enable_history_by_user: {
          type: :proc,
          default: ->(user) { true },
          dependents: [ -> (i) { i.enable_history? }, -> (i) { i.enable? } ]
        },
        enable_actions: {
          type: :boolean,
          default: true,
          dependents: [ -> (i) { i.enable? } ]
        },
        admin_velocity_max: { type: :integer, default: ENV.fetch('ADMIN_VELOCITY_MAX', 20).to_i },
        admin_velocity_max_in_frame: { type: :duration, default: ENV.fetch('ADMIN_VELOCITY_MAX_IN_FRAME', 1).to_i.hours},
        admin_velocity_frame: { type: :duration, default: ENV.fetch('ADMIN_VELOCITY_FRAME', 5).to_i.hours },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
