require 'rails_base/configuration/base'
require 'rails_base/admin/index_tile'
require 'rails_base/admin/default_index_tile'

module RailsBase
  module Configuration
    class Admin < Base
      DEFAULT_VALUES = {
        enable: {
          type: :boolean,
          default: true,
          description: 'Enable Admin capabilities'
        },
        enable_history: {
          type: :boolean,
          default: true,
          dependents: [ -> (i) { i.enable? } ],
          description: 'Enable Users to view history'
        },
        view_admin_page: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_view_only? },
          dependents: [ -> (i) { i.enable? } ],
          description: 'Users that can view admin index'
        },
        enable_history_by_user: {
          type: :proc,
          default: ->(user) { true },
          dependents: [ -> (i) { i.enable_history? }, -> (i) { i.enable? } ],
          description: 'Users that can view history page',
        },
        enable_actions: {
          type: :boolean,
          default: true,
          dependents: [ -> (i) { i.enable? } ],
          description: 'Enable history of admin actions',
        },
        admin_page_tiles: {
          type: :array,
          klass_type: [RailsBase::Admin::IndexTile],
          default: RailsBase::Admin::IndexTile.defaults,
          decipher: ->(thing) { thing.description },
          description: 'List of tiles on admin page',
        },
        enable_sso_tile: {
          type: :boolean,
          default: true,
          dependents: [ -> (i) { i.enable? } ],
          description: 'Display SSO tile on admin page',
        },
        sso_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          dependents: [ -> (i) { i.enable_sso_tile? } ],
          description: 'List of users that can use SSO on admin page',
        },
        impersonate_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          description: 'List of users that can use impersonation on admin page',
        },
        admin_type_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_owner? },
          description: 'List of users that can change other users admin',
        },
        mfa_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          description: 'List of users that can change MFA on admin page',
        },
        phone_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          description: 'List of users that can change users phone number on admin page',
        },
        email_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          description: 'List of users that can change users email on admin page',
        },
        email_validate_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          description: 'List of users that can change email validated on admin page',
        },
        name_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          description: 'List of users that can change users name on admin page',
        },
        active_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          description: 'List of users that can change active on admin page',
        },
        config_page: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          description: 'List of users that can view the configuration page',
        },
        admin_velocity_max: {
          type: :integer,
          default: ENV.fetch('ADMIN_VELOCITY_MAX', 20).to_i,
          description: 'Max number of risky changes an admin can make in a given window',
        },
        admin_velocity_max_in_frame: {
          type: :duration,
          default: ENV.fetch('ADMIN_VELOCITY_MAX_IN_FRAME', 1).to_i.hours,
          description: 'Sliding window for admin_velocity_max',

        },
        admin_velocity_frame: {
          type: :duration,
          default: ENV.fetch('ADMIN_VELOCITY_FRAME', 5).to_i.hours,
          description: 'Debug purposes. How long to keep admin_velocity_max attempts',
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
