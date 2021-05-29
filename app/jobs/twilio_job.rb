require 'twilio_helper'

class TwilioJob < RailsBase::ApplicationJob
  queue_as RailsBase.config.mfa.active_job_queue

  def perform(message:, to:)
    TwilioHelper.send_sms(message: message, to: to)
  end
end
