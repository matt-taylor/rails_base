require 'twilio_helper'
require 'velocity_limiter'

module RailsBase
  class AdminRiskyMfaSend < RailsBase::ServiceBase
    include ActionView::Helpers::DateHelper
    include VelocityLimiter

    class NoPhoneNumber < StandardError; end

    MAX_USE_COUNT = 1.freeze
    DATA_USE = :numeric
    VELOCITY_MAX = 45 || Rails.configuration.twilio_velocity_max
    VELOCITY_MAX_IN_FRAME = 10.minutes || Rails.configuration.twilio_velocity_max_in_frame.hour
    VELOCITY_FRAME = 30.minutes || Rails.configuration.twilio_velocity_frame.hour
    EXPIRES_AT = 2.minutes

    delegate :user, to: :context
    delegate :reason, to: :context

    def call
      validate_phone!

      velocity = velocity_limit_reached?
      context.fail!(message: velocity[:msg]) if velocity[:reached]

      data_point = create_short_lived_data
      send_twilio!(data_point.data)
      context.short_lived_data = data_point
      context.message = "MFA code has been succesfully sent. you have #{EXPIRES_AT}"
    end

    def send_twilio!(code)
      TwilioHelper.send_sms(message: message(code), to: user.phone_number)
      log(level: :info, msg: "Sent twilio message to #{user.phone_number}")
    rescue StandardError => e
      log(level: :error, msg: "Error caught #{e.class.name}")
      log(level: :error, msg: "Failed to send sms to #{user.phone_number}")
      context.fail!(message: "Failed to send sms. Please retry logging in.")
    end

    def message(code)
      "Hello #{user.full_name}. Here is your admin verification code #{code}."
    end

    def create_short_lived_data
      params = {
        user: user,
        max_use: MAX_USE_COUNT,
        reason: reason,
        data_use: DATA_USE,
        expires_at: EXPIRES_AT.from_now,
        length: Authentication::Constants::MFA_LENGTH,
      }
      ShortLivedData.create_data_key(params)
    end

    def velocity_max_in_frame
      VELOCITY_MAX_IN_FRAME
    end

    def velocity_max
      VELOCITY_MAX
    end

    def velocity_frame
      VELOCITY_FRAME
    end

    def cache_key
      "#{self.class.name.downcase}.#{user.id}"
    end

    def validate_phone!
      context.fail!("No phone for user [#{user.id}] [#{user.phone_number}]") if user.phone_number.nil?
    end

    def validate!
      raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User
      raise "Expected reason to be a present." if reason.nil?
    end
  end
end
