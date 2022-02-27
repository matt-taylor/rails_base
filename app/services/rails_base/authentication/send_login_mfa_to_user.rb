require 'twilio_helper'
require 'velocity_limiter'

module RailsBase::Authentication
  class SendLoginMfaToUser < RailsBase::ServiceBase
    include ActionView::Helpers::DateHelper
    include VelocityLimiter

    class NoPhoneNumber < StandardError; end

    MAX_USE_COUNT = 1.freeze
    DATA_USE = :numeric

    delegate :user, to: :context
    delegate :expires_at, to: :context

    def call
      velocity = velocity_limit_reached?
      context.fail!(message: velocity[:msg]) if velocity[:reached]

      data_point = create_short_lived_data
      send_twilio!(data_point.data)
      context.short_lived_data = data_point
    end

    def send_twilio!(code)
      TwilioJob.perform_later(message: message(code), to: user.phone_number)
      log(level: :info, msg: "Sent twilio message to #{user.phone_number}")
    rescue StandardError => e
      log(level: :error, msg: "Error caught #{e.class.name}")
      log(level: :error, msg: "Failed to send sms to #{user.phone_number}")
      context.fail!(message: "Failed to send sms. Please retry logging in.")
    end

    def message(code)
      "Hello #{user.full_name}. Here is your verification code #{code}."
    end

    def create_short_lived_data
      params = {
        user: user,
        max_use: MAX_USE_COUNT,
        reason: Constants::MFA_REASON,
        data_use: DATA_USE,
        ttl: Constants::SLMTU_TTL,
        expires_at: expires_at,
        length: Constants::MFA_LENGTH,
      }
      ShortLivedData.create_data_key(**params)
    end

    def velocity_max_in_frame
      RailsBase.config.mfa.twilio_velocity_max_in_frame
    end

    def velocity_max
      RailsBase.config.mfa.twilio_velocity_max
    end

    def velocity_frame
      RailsBase.config.mfa.twilio_velocity_frame
    end

    def cache_key
      "#{self.class.name.downcase}.#{user.id}"
    end

    def validate!
      raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User
      if expires_at && !(expires_at.is_a?(ActiveSupport::TimeWithZone))
        raise "Expected expires_at to be a ActiveSupport::TimeWithZone. Given #{expires_at.class}"
      end

      raise NoPhoneNumber, "No phone for user [#{user.id}] [#{user.phone_number}]" if user.phone_number.nil?
    end
  end
end
