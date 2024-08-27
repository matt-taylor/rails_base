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
        reauth_strategy: {
          type: :klass,
          default: -> (_val) { RailsBase::Mfa::Strategy::EveryRequest },
          custom: ->(val) { (Proc === val ? val.call(nil) : val).ancestors.include?(RailsBase::Mfa::Strategy::Base) },
          msg: "Invalid ReAuth Strategy. Provided class must be descendent of RailsBase::Mfa::Strategy::Base",
          description: "Value is expected to be a descendent of RailsBase::Mfa::Strategy::Base. It can be lazily loaded via a proc",
          on_assignment: ->(val, instance) { instance.reauth_strategy = (Proc === val ? val.call(nil) : val) },
        },
        reauth_duration: {
          type: :duration,
          default: 2.days,
          description: "When `reauth_strategy` is `time_based`, this value is the max time before MFA is required",
        }
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
