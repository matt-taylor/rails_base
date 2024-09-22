require 'twilio_helper'

module RailsBase::Authentication
  class SingleSignOnSend < RailsBase::ServiceBase
    delegate :user, to: :context
    delegate :token_length, to: :context
    delegate :uses, to: :context
    delegate :expires_at, to: :context
    delegate :reason, to: :context
    delegate :token_type, to: :context
    delegate :url_redirect, to: :context
    delegate :msg_proc, to: :context

    SSO_DECISION_TWILIO = :twilio
    SSO_DECISION_EMAIL = :email
    VALID_SSO_DECISIONS = [SSO_DECISION_TWILIO, SSO_DECISION_EMAIL].freeze

    def call
      # :nocov:
      # redundant check, unless user overwrites `sso_decision_type`
      unless VALID_SSO_DECISIONS.include?(sso_decision_type)
        context.fail!(message: "Invalid sso decision. Given [#{sso_decision_type}]. Expected [#{VALID_SSO_DECISIONS}]")
      end
      # :nocov:

      params = {
        user: user,
        token_length: token_length,
        uses: uses,
        expires_at: expires_at,
        reason: reason || RailsBase::Authentication::Constants::SSO_LOGIN_REASON,
        token_type: token_type,
        url_redirect: url_redirect
      }
      datum = SingleSignOnCreate.(**params)
      context.fail!(message: 'Failed to create SSO token. Try again') if datum.failure?

      url = sso_url(data: datum.data.data)
      case sso_decision_type
      when SSO_DECISION_TWILIO
        context.sso_destination = :sms
        send_to_twilio!(message: message(url: url, full_name: user.full_name))
      when SSO_DECISION_EMAIL
        context.sso_destination = :email
        send_to_email!(message: message(url: url, full_name: user.full_name))
      end
    end

    # This method is expected to be overridden by the main app
    # This is the default message
    # Might consider shipping this to a locales that can be easily overridden in downstream app
    def message(url:, full_name:)
      return msg_proc.call(url, full_name) if msg_proc.is_a?(Proc)

      "Hello #{user.full_name}. This is your SSO link to your favorite site.\n#{url}"
    end

    # This method is expected to be overridden by the main app
    # This is expected default behavior if SSO is available
    def sso_decision_type
      if phone.present?
        SSO_DECISION_TWILIO
      elsif user.email_validated
        SSO_DECISION_EMAIL
      else
        log(level: :error, msg: "No SSO will be sent for user #{user.id}. No email/phone available to send to at this time")
        context.fail!(message: "User does not have a validated email nor phone number. Unable to do SSO")
      end
    end

    def send_to_twilio!(message:)
      TwilioJob.perform_later(message: message, to: phone)
      log(level: :info, msg: "Sent twilio message to #{phone}")
    rescue StandardError => e
      log(level: :error, msg: "Error caught #{e.class.name}")
      log(level: :error, msg: "Error caught #{e.message}")
      log(level: :error, msg: "Failed to send sms to #{phone}")
      context.fail!(message: "Failed to send sms to user. Try again.")
    end

    def phone
      context.phone_number || user.phone_number
    end

    def send_to_email!(message:)
      RailsBase::EventMailer.send_sso(user: user, message: message).deliver_me
    rescue StandardError => e
      log(level: :error, msg: "Error caught #{e.class.name}")
      log(level: :error, msg: "Failed to send email to #{user.email}")
      context.fail!(message: "Failed to send email to user. Try again.")
    end

    def sso_url(data:)
      params = {
        data: data,
        host: Constants::BASE_URL,
      }
      params[:port] = Constants::BASE_URL_PORT if Constants::BASE_URL_PORT
      Constants::URL_HELPER.sso_retrieve_url(params)
    end

    def validate!
      raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User

      # Other validations take place in SingleSignOnCreate class
    end
  end
end
