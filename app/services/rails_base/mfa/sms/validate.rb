# frozen_string_literal: true

module RailsBase::Mfa::Sms
  class Validate < RailsBase::ServiceBase
    delegate :params, to: :context
    delegate :session_mfa_user_id, to: :context
    delegate :current_user, to: :context
    delegate :input_reason, to: :context
    delegate :sms_code, to: :context
    delegate :mfa_event, to: :context

    def call
      if sms_code.present?
        log(level: :info, msg: "Raw sms code was passed in")
        mfa_code = sms_code
      else
        log(level: :info, msg: "Code Array was passed in. Manipulating Data first")
        array = convert_to_array
        if array.length != RailsBase::Authentication::Constants::MFA_LENGTH
          log(level: :warn, msg: "Not enough params for MFA code. Given #{array}. Expected of length #{RailsBase::Authentication::Constants::MFA_LENGTH}")
          context.fail!(message: RailsBase::Authentication::Constants::MV_FISHY, redirect_url: RailsBase.url_routes.new_user_session_path, level: :alert)
        end

        mfa_code = array.join
      end


      log(level: :info, msg: "mfa code received: #{mfa_code}")
      datum = get_short_lived_datum(mfa_code)
      log(level: :info, msg: "Datum returned with: #{datum}")

      validate_datum?(datum)
      validate_user_consistency?(datum)
      validate_current_user?(datum) if current_user

      context.user = datum[:user]
    end

    def validate_current_user?(datum)
      return true if current_user.id == datum[:user].id

      # User MFA for a different user matched the session token
      # However, those did not match the current user signed in
      # Something is very 🐟
      log(level: :error, msg: "Someone is a teapot. Current logged in user does not equal mfa code.")
      context.fail!(message: 'You are a teapot', redirect_url: RailsBase.url_routes.signout_path, level: :warn)
    end

    def validate_datum?(datum)
      return true if datum[:valid]

      if datum[:found]
        # MFA is either expired or the incorrect reason. Either way it does not match
        msg = "Errors with MFA: #{datum[:invalid_reason].join(", ")}. Please login again"
        log(level: :warn, msg: msg)
        context.fail!(message: msg, redirect_url: RailsBase.url_routes.new_user_session_path, level: :warn)
      end

      # MFA does not exist for any reason type
      log(level: :warn, msg: "Could not find MFA code. Incorrect MFA code")

      context.fail!(message: "Incorrect SMS code.", redirect_url: RailsBase.url_routes.mfa_with_event_path(mfa_event: mfa_event.event, type: RailsBase::Mfa::SMS), level: :warn)
    end

    def validate_user_consistency?(datum)
      return true if datum[:user].id == session_mfa_user_id.to_i
      log(level: :warn, msg: "Datum user does not match session user. [#{datum[:user].id}, #{session_mfa_user_id.to_i}]")

      # MFA session token user does not match the datum user
      # Something is very 🐟
      context.fail!(message: RailsBase::Authentication::Constants::MV_FISHY, redirect_url: RailsBase.url_routes.new_user_session_path, level: :alert)
    end

    def get_short_lived_datum(mfa_code)
      log(level: :debug, msg: "Looking for #{mfa_code} with reason #{reason}")
      ShortLivedData.find_datum(data: mfa_code, reason: reason)
    end

    def convert_to_array
      array = []
      return array unless params.dig(:mfa).respond_to? :keys

      RailsBase::Authentication::Constants::MFA_LENGTH.times do |index|
        var_name = "#{RailsBase::Authentication::Constants::MV_BASE_NAME}#{index}".to_sym
        array << params[:mfa][var_name]
      end

      array.compact
    end

    def reason
      input_reason || RailsBase::Authentication::Constants::MFA_REASON
    end

    def validate!
      if sms_code.nil?
        raise 'params is not present' if params.nil?
      end

      raise 'mfa_event is expected to be a RailsBase::MfaEvent' unless RailsBase::MfaEvent === mfa_event

      raise 'session_mfa_user_id is not present' if session_mfa_user_id.nil?
    end
  end
end
