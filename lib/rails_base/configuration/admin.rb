require 'rails_base/configuration/base'
require 'rails_base/admin/index_tile'
require 'rails_base/admin/default_index_tile'

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
          default: ->(user) { user.active && user.at_least_view_only? },
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
        admin_page_tiles: {
          type: :array,
          klass: [],
          default: RailsBase::Admin::IndexTile.defaults,
        },
        enable_sso_tile: {
          type: :boolean,
          default: true,
          dependents: [ -> (i) { i.enable? } ]
        },
        sso_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          dependents: [ -> (i) { i.enable_sso_tile? } ]
        },
        impersonate_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
        },
        admin_type_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_owner? },
        },
        mfa_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
        },
        phone_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
        },
        email_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
        },
        email_validate_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
        },
        name_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
        },
        active_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
        },

        admin_velocity_max: { type: :integer, default: ENV.fetch('ADMIN_VELOCITY_MAX', 20).to_i },
        admin_velocity_max_in_frame: { type: :duration, default: ENV.fetch('ADMIN_VELOCITY_MAX_IN_FRAME', 1).to_i.hours},
        admin_velocity_frame: { type: :duration, default: ENV.fetch('ADMIN_VELOCITY_FRAME', 5).to_i.hours },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
