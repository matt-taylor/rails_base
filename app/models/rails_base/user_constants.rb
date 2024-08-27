module RailsBase
  module UserConstants
    ADMIN_ENUMS = [
      ADMIN_ROLE_NONE = :none,
      ADMIN_ROLE_VIEW_ONLY = :view_only,
      ADMIN_ROLE_SUPER = :super,
      ADMIN_ROLE_OWNER = :owner,
    ]

    SOFT_DESTROY_PARAMS = {
      mfa_sms_enabled: false,
      mfa_otp_enabled: false,
      email_validated: false,
      last_mfa_sms_login: nil,
      last_mfa_otp_login: nil,
      encrypted_password: '',
      phone_number: nil,
    }

    SAFE_AUTOMAGIC_UPGRADE_COLS = {
      active: ->(user) { RailsBase.config.admin.active_tile_users?(user) } ,
      admin: ->(user) { RailsBase.config.admin.admin_type_tile_users?(user) } ,
      email: ->(user) { RailsBase.config.admin.email_tile_users?(user) } ,
      email_validated: ->(user) { RailsBase.config.admin.email_validate_tile_users?(user) } ,
      mfa_sms_enabled: ->(user) { RailsBase.config.admin.mfa_tile_users?(user) } ,
      mfa_otp_enabled: ->(user) { RailsBase.config.admin.mfa_tile_users?(user) } ,
      phone_number: ->(user) { RailsBase.config.admin.phone_tile_users?(user) } ,
      last_known_timezone: ->(user) { RailsBase.config.admin.modify_timezone_tile_users?(user) }
    }
  end
end
