module RailsBase::Authentication::Totp
  class OtpMetadata < RailsBase::ServiceBase
    delegate :user, to: :context

    def call
      context.metadata = user.otp_metadata(safe: true)
    rescue => e
      log(level: :error, msg: "Failed to retreive OTP data: #{e.message}")
      log(level: :error, msg: e.backtrace)
      context.fail!(message: "Failed to retrieve Metadata for Code")
    end

    def validate!
      raise "Expected user to be a User. " unless User === user
    end
  end
end
