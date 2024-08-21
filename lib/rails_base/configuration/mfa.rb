require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Mfa < Base
      MFA_TYPE_OPTIONS = [ DEFAULT_TYPE = :totp, :twilio ]
      DEFAULT_VALUES = {
        enable: {
          type: :boolean,
          default: ENV.fetch('MFA_ENABLE', 'true')=='true',
          description: 'Enable MFA with SMS or TOTP verification. When not enabled, there are some interesting consequences',
        },
        enable_twilio: {
          type: :boolean,
          default: true,
          description: 'Add Twilio as an MFA option.',
        },
        enable_totp: {
          type: :boolean,
          default: true,
          description: 'Add TOTP as an MFA option.',
        },
        max_attempts_before_password_expire: {
          type: :integer,
          default: 5,
          description: 'Max MFA attempts before password expires and password must get re-entered',
        },
        max_password_expires_before_account_locked: {
          type: :integer,
          default: 5,
          description: 'Max number of password expires before account is locked',
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
