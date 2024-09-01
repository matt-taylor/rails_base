# frozen_string_literal: true

module RailsBase
  class MfaEvent
    ENABLE_SMS_EVENT = :enable
    DISABLE_SMS_EVENT = :disable
    FORGOT_PASSWORD = :forgot_password
    ADMIN_VERIFY = :admin_verify

    class InvalidParameter < ArgumentError; end

    attr_reader :set_satiated_on_success, :satiated, :access_count, :flash_notice, :sign_in_user,
      :invalid_redirect, :ttl, :user_id, :event, :description, :death_time, :redirect, :params

    def self.admin_actions(user:)
      params = {
        user: user,
        event: ADMIN_VERIFY,
        description: "MFA needed to complete admin actions",
        ttl: 2.minutes,
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
        description: "MFA needed to login to #{RailsBase.app_name}",
        ttl: 2.minutes,
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
        description: "To enable MFA for SMS",
        ttl: 5.minutes,
        invalid_redirect: "",
        redirect: "",
        flash_notice: ""
      }

      new(**params)
    end

    def self.sms_disable(user:)
      params = {
        user: user,
        event: DISABLE_SMS_EVENT,
        description: "To disable MFA for SMS",
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
        description: "Forgot Password",
        ttl: 1.hour || 5.minutes,
        invalid_redirect: RailsBase.url_routes.unauthenticated_root_path,
        redirect: RailsBase.url_routes.reset_password_input_path(data:),
        flash_notice: "MFA success. You may now reset your forgotten password",
        access_count_max: 1,
      }

      new(**params)
    end

    def initialize(event:, flash_notice:, description:, redirect:, ttl: nil, death_time: nil, user_id: nil, user: nil, invalid_redirect: nil, sign_in_user: false, access_count: 0, satiated: false, **params)
      @sign_in_user = sign_in_user

      @ttl = ttl
      @death_time = begin
        raw = (death_time || ttl&.from_now)
        Time.zone.parse(raw.to_s) rescue nil
      end
      @user_id = user_id || user.id rescue nil

      @access_count = access_count
      @event = event
      @flash_notice = flash_notice
      @description = description
      @redirect = redirect
      @invalid_redirect = invalid_redirect || RailsBase.url_routes.authenticated_root_path
      @clear_after_use = params.fetch(:clear_after_use, true)
      @access_count_max = params.fetch(:access_count_max, nil)
      @satiated = satiated
      @set_satiated_on_success = params.fetch(:set_satiated_on_success, true)
      @params = params

      validate_data!

      increase_access_count!
    end

    def clear_after_use
      params.fetch(:clear_after_use, true)
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

    def to_hash
      {
        death_time:,
        description:,
        event:,
        redirect:,
        ttl:,
        user_id:,
        invalid_redirect:,
        sign_in_user:,
        flash_notice:,
        access_count:,
        satiated:,
        **params.deep_symbolize_keys,
      }
    end

    private

    def validate_data!
      raise_event!(value: @event, name: :event, klass: [String, Symbol])
      raise_event!(value: @description, name: :description, klass: [String])
      raise_event!(value: @death_time, name: :death_time, klass: [ActiveSupport::TimeWithZone])
      raise_event!(value: @redirect, name: :redirect, klass: [String])
      raise_event!(value: @params, name: :params, klass: [Hash])
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
