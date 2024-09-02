# frozen_string_literal: true

module RailsBase
  class MfaEvent
    ENABLE_SMS_EVENT = :sms_enable
    DISABLE_SMS_EVENT = :sms_disable
    FORGOT_PASSWORD = :forgot_password
    ADMIN_VERIFY = :admin_verify

    class InvalidParameter < ArgumentError; end

    attr_reader :only_mfa, :phone_number, :set_satiated_on_success, :satiated, :access_count, :flash_notice, :sign_in_user,
      :invalid_redirect, :ttl, :user_id, :event, :description, :death_time, :redirect, :params, :access_count_max

    def self.admin_actions(user:)
      params = {
        user: user,
        event: ADMIN_VERIFY,
        ttl: 30.seconds,
        redirect: "",
        invalid_redirect: "",
        flash_notice: "",
      }

      new(**params)
    end

    def self.login_event(user:)
      params = {
        user: user,
        event: :login,
        ttl: 1.minutes,
        redirect: RailsBase.url_routes.authenticated_root_path,
        invalid_redirect: RailsBase.url_routes.unauthenticated_root_path,
        sign_in_user: true,
        flash_notice: "Welcome #{user.full_name}. You have succesfully signed in"
      }

      new(**params)
    end

    # This is a JSON event not html; Can leave redirects/notice empty
    def self.sms_enable(user:)
      params = {
        user: user,
        event: ENABLE_SMS_EVENT,
        ttl: 5.minutes,
        invalid_redirect: RailsBase.url_routes.user_settings_path,
        redirect: RailsBase.url_routes.user_settings_path,
        flash_notice: ""
      }

      new(**params)
    end

    def self.sms_disable(user:)
      params = {
        user: user,
        event: DISABLE_SMS_EVENT,
        ttl: 5.minutes,
        invalid_redirect: RailsBase.url_routes.user_settings_path,
        redirect: RailsBase.url_routes.user_settings_path,
        flash_notice: "SMS option for MFA is disabled"
      }

      new(**params)
    end

    def self.forgot_password(user:, data:)
      params = {
        user: user,
        event: FORGOT_PASSWORD,
        ttl: 2.minutes,
        invalid_redirect: RailsBase.url_routes.unauthenticated_root_path,
        redirect: RailsBase.url_routes.reset_password_input_path(data:),
        flash_notice: "MFA success. You may now reset your forgotten password",
        access_count_max: 1,
      }

      new(**params)
    end

    def initialize(event:, flash_notice:, redirect:, only_mfa: nil, phone_number: nil, ttl: nil, death_time: nil, user_id: nil, user: nil, invalid_redirect: nil, sign_in_user: false, access_count: 0, access_count_max: nil, satiated: false, set_satiated_on_success: true)
      @death_time = begin
        raw = (death_time || ttl&.from_now)
        Time.zone.parse(raw.to_s) rescue nil
      end

      @access_count = access_count
      @access_count_max = access_count_max
      @event = event
      @flash_notice = flash_notice
      @invalid_redirect = invalid_redirect || RailsBase.url_routes.authenticated_root_path
      @only_mfa = only_mfa
      @phone_number = phone_number
      @redirect = redirect
      @satiated = satiated
      @set_satiated_on_success = set_satiated_on_success
      @sign_in_user = sign_in_user
      @user_id = user_id || user.id rescue nil

      validate_data!
    end

    def to_hash
      {
        access_count:,
        access_count_max:,
        death_time:,
        event:,
        flash_notice:,
        invalid_redirect:,
        only_mfa:,
        phone_number:,
        redirect:,
        satiated:,
        set_satiated_on_success:,
        sign_in_user:,
        user_id:,
      }
    end

    def access_count
      @access_count
    end

    def satiated!
      @satiated = true
    end

    def satiated?
      @satiated
    end

    def increase_access_count!
      @access_count += 1
    end

    def valid?
      valid_by_death_time? && valid_by_access_count?
    end

    def valid_by_death_time?
      death_time >= Time.now
    end

    def valid_by_access_count?
      return true if @access_count_max.nil?

      @access_count_max
    end

    def invalid_reasons
      arr = []
      arr << "Max Access count reached" unless valid_by_death_time?
      arr << "#{event} has expired" unless valid_by_access_count?

      arr
    end

    private

    def validate_data!
      raise_event!(value: @event, name: :event, klass: [String, Symbol])
      raise_event!(value: @death_time, name: :death_time, klass: [ActiveSupport::TimeWithZone])
      raise_event!(value: @redirect, name: :redirect, klass: [String])
      raise_event!(value: @user_id, name: :user, klass: [Integer])
      raise_event!(value: @flash_notice, name: :flash_notice, klass: [String])
      raise_event!(value: @access_count, name: :access_count, klass: [Integer])
      raise_event!(value: @access_count_max, name: :access_count_max, klass: [Integer, NilClass])
    end

    def raise_event!(value:, name:, klass:, &blk)
      boolean = klass.include?(value.class)
      raise_message = nil
      if boolean && block_given?
        raise_message = yield(value)
      end
      boolean = false if raise_message
      return if boolean

      message = raise_message || "@#{name}=#{value}. Value is expected to be in #{klass}"
      raise InvalidParameter, message
    end
  end
end
