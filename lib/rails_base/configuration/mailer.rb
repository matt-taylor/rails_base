require 'rails_base/configuration/base'
require 'rails_base/admin/index_tile'
require 'rails_base/admin/default_index_tile'

module RailsBase
  module Configuration
    class Mailer < Base
      CUSTOM_MAILER_METHOD = :deliver_me

      FROM_PROC = Proc.new do |val, _instance|
        hash = Rails.configuration.action_mailer.default_options || {}
        ACTION_MAILER_PROC.call(:default_options, hash.merge(from: val))
      end

      SMTP_OPTIONS_PROC = Proc.new do |field, val|
        hash = Rails.configuration.action_mailer.smtp_settings || {}
        ACTION_MAILER_PROC.call(:smtp_settings, hash.merge(field.to_sym => val))
      end

      MAIL_FROM_PROC = Proc.new do |val, _instance|
        Rails.configuration.mail_from = val
      end

      ACTION_MAILER_PROC = Proc.new do |name, val|
        Rails.configuration.action_mailer.public_send(:"#{name}=", val)
      end

      MAILER_METHOD = Proc.new do |val, instance|
        unless ActionMailer::MessageDelivery.instance_methods.include?(val.to_sym)
          raise ArgumentError, "config.mailer.delivery = :#{val} is not a defined method on ActionMailer::MessageDelivery"
        end
        ActionMailer::MessageDelivery.define_method(CUSTOM_MAILER_METHOD) do
          public_send(val)
        end
      end


      DEFAULT_VALUES = {
        from: {
          type: :string,
          default: ENV.fetch('GMAIL_USER_NAME', nil),
          on_assignment: [FROM_PROC, ->(val, _instance) { SMTP_OPTIONS_PROC.call(:user_name, val)}, MAIL_FROM_PROC],
          description: 'UserName for emails'
        },
        password: {
          type: :string,
          default: ENV.fetch('GMAIL_PASSWORD', nil),
          secret: true,
          on_assignment: ->(val, _instance) { SMTP_OPTIONS_PROC.call(:password, val) },
          description: 'Password for emails: Often times is an app password: https://support.google.com/accounts/answer/185833?hl=en'
        },
        address: {
          type: :string,
          default: 'smtp.gmail.com',
          on_assignment: ->(val, _instance) { SMTP_OPTIONS_PROC.call(:address, val) },
          description: 'Value is dependent on email provider'
        },
        port: {
          type: :integer,
          default: 587,
          on_assignment: ->(val, _instance) { SMTP_OPTIONS_PROC.call(:port, val) },
          description: 'Port to send emails from'
        },
        authentication: {
          type: :string,
          default: 'plain',
          on_assignment: ->(val, _instance) { SMTP_OPTIONS_PROC.call(:authentication, val) },
          description: 'Authentication type for emails'
        },
        enable_starttls_auto: {
          type: :boolean,
          default: true,
          on_assignment: ->(val, _instance) { SMTP_OPTIONS_PROC.call(:enable_starttls_auto, val) },
          description: 'Enable encryption for emails'
        },
        delivery_method: {
          type: :symbol,
          default: Rails.env.test? ? :test : :smtp,
          on_assignment: ->(val, _instance) { ACTION_MAILER_PROC.call(:delivery_method, val) },
          description: 'Delivery method. Test default is :test. Everything else default is :smtp'
        },
        perform_deliveries: {
          type: :boolean,
          default: true,
          on_assignment: ->(val, _instance) { ACTION_MAILER_PROC.call(:perform_deliveries, val) },
          description: 'When false, mail does not get delivered'
        },
        raise_delivery_errors: {
          type: :boolean,
          default: true,
          on_assignment: ->(val, _instance) { ACTION_MAILER_PROC.call(:raise_delivery_errors, val) },
          description: 'Raise when mail cannot be delivered'
        },
        preview_path: {
          type: :path,
          default: RailsBase::Engine.root.join('spec','mailers','previews'),
          on_assignment: ->(val, _instance) { ACTION_MAILER_PROC.call(:preview_path, val) },
          description: 'Path for mailer previews'
        },
        delivery: {
          type: :symbol,
          default: 'deliver_now',
          on_assignment: MAILER_METHOD,
          description: "Mailers have a custom delivery method of #{CUSTOM_MAILER_METHOD}. Override this to deliver_later if you have the active_job_adapter running"
        },
      }

      attr_accessor *DEFAULT_VALUES.keys
    end
  end
end
