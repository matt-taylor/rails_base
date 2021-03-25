require 'twilio-ruby'

class TwilioHelper
  class << self
    TWILIO_ACCOUNT_SID = Rails.configuration.twilio_sid
    TWILIO_AUTH_TOKEN = Rails.configuration.twilio_auth_token
    TWILIO_FROM_NUMBER = Rails.configuration.twilio_from_number

    def send_sms(message:, to:)
      Rails.logger.info "Sending Twilio message:[#{message}] to [#{to}]"
      msg = client.messages.create(
        from: TWILIO_FROM_NUMBER,
        to: to,
        body: message
      )

      Rails.logger.info("SID: #{msg.sid}")
    end

    private

    def client
      @client ||= Twilio::REST::Client.new(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
    end
  end
end
