require 'rails_base/configuration/base'
require 'rails_base/admin/index_tile'
require 'rails_base/admin/default_index_tile'
require RailsBase::Engine.root.join('app', 'models', 'rails_base', 'user_constants.rb')

module RailsBase
  module Configuration
    class Admin < Base

      include RailsBase::UserConstants

      ADMIN_TYPE_PROC = Proc.new do |hash|
        RailsBase.config.admin.admin_types.map do |type|
          {
            filter: "Admin Type: #{type}",
            proc: ->(user, admin_user) { user.public_send("admin_#{type}?") },
            id: "#{hash[:id]}_#{type}",
          }
        end
      end

      DEFAULT_ADMIN_TYPE = {
        filter: '',
        id: "admin",
        proc: ->(_user, _admin_user) { },
        replace:  ADMIN_TYPE_PROC,
      }

      DEFAULT_ADMIN_SELF = {
        filter: 'My User',
        id: 'my_admin_user',
        proc: ->(user, admin_user) { user == admin_user }
      }

      DEFAULT_ADMIN_ACTIVE = {
        filter: 'Active Users',
        id: 'active_users',
        proc: ->(user, admin_user) { user.active? }
      }

      DEFAULT_EMAIL_VALIDATED = {
        filter: 'Email Validated',
        id: 'email_validated',
        proc: ->(user, admin_user) { user.email_validated? }
      }

      DEFAULT_MFA_SMS_ENABLED = {
        filter: 'MFA SMS Enabled',
        id: 'mfa_sms_enabled',
        proc: ->(user, admin_user) { user.mfa_sms_enabled? }
      }

      DEFAULT_PAGE_FILTER = [DEFAULT_ADMIN_TYPE, DEFAULT_ADMIN_SELF, DEFAULT_ADMIN_ACTIVE, DEFAULT_EMAIL_VALIDATED, DEFAULT_MFA_SMS_ENABLED].flatten
      DEFAULT_VALUES = {
        enable: {
          type: :boolean,
          default: true,
          description: 'Enable Admin capabilities'
        },
        admin_types: {
          type: :array,
          klass_type: [Symbol],
          default: ADMIN_ENUMS,
          on_assignment: ->(val, instance) { instance._assert_admin_type },
          description: 'List of admin types. Assignment order is important. Note: :none gets prepended as this is default. Note: :owner, gets appended to this array as the last, highest priority',
          decipher: ->(thing) { thing },
        },
        default_admin_type: {
          type: :values,
          expect_values: ->(instance) { instance.admin_types },
          default: ADMIN_ROLE_NONE,
          description: 'Starting value for new users. Dependent on `admin_types` values',
          decipher: ->(thing) { thing },
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
        # Next value is dependent on admin_types. Must be defined after
        admin_page_filter: {
          type: :array,
          # klass_type: [Array],
          on_assignment: ->(val, instance) { instance._admin_type_replace_proc },
          default: DEFAULT_PAGE_FILTER,
          description: 'List of filters on admin page.',
          decipher: ->(thing) { thing[:filter] },
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
        modify_timezone_tile_users: {
          type: :proc,
          default: ->(user) { user.active && user.at_least_super? },
          description: 'List of users that can change the timezone for a given user',
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
        admin_impersonate_redirect:{
          type: :proc,
          default: ->(*) { RailsBase.url_routes.authenticated_root_path },
          description: 'Redirection to impersonation -- Landing page when having an identity crisis',
        },
        admin_impersonate_return:{
          type: :proc,
          default: ->(*) { RailsBase.url_routes.admin_base_path },
          description: 'Redirection from impersonation -- Page to return from when you have found yourself',
        }
      }

      attr_accessor *DEFAULT_VALUES.keys

      def _assert_admin_type
        admin_types.delete(ADMIN_ROLE_OWNER)
        admin_types.delete(ADMIN_ROLE_NONE)
        admin_types << ADMIN_ROLE_OWNER
        admin_types.prepend ADMIN_ROLE_NONE
        convenience_methods
      end

      def _admin_type_replace_proc
        admin_page_filter.each_with_index do |value, index|
          next unless value[:replace].present?

          admin_page_filter[index] = ADMIN_TYPE_PROC.call(value)
        end
        admin_page_filter.flatten!
      end

      def convenience_methods
        # defines instance methods like
        # user.at_least_super?
        # user.at_least_owner?
        # user.admin_super!
        # user.admin_owner!
        # User.admin_owner
        # User.admin_owners
        # This is 100% dependent upon keeping `admin_types` in order of precedence
        require RailsBase::Engine.root.join('app','models', 'user.rb')
        admin_types.each do |type|
          ::User._def_admin_convenience_method!(admin_method: type)
        end
      end
    end
  end
end
