module RailsBase::Authentication
	class UpdatePhoneSendVerification < RailsBase::ServiceBase
		delegate :user, to: :context
		delegate :phone_number, to: :context

		EXPECTED_LENGTH = 10

		def call
			if sanitized_phone_number.nil?
				context.fail!(message: "Unexpected params passed")
			end

			# should be after successful twilio MFA send
			# requires a bit of a restructure that I dont have time for
			update_user_number!

			twilio_sms = RailsBase::Mfa::Sms::Send.call(user: user.reload)

			if twilio_sms.failure?
				log(level: :error, msg: "Failed with #{twilio_sms.message}")
				context.fail!(message: twilio_sms.message)
			end
			context.expires_at = twilio_sms.short_lived_data.death_time
			context.mfa_randomized_token =
			  MfaSetEncryptToken.call(user: user, expires_at: context.expires_at, purpose: Constants::MSET_PURPOSE).encrypted_val
		end

		def update_user_number!
			log(level: :info, msg: "Received: #{phone_number}. Sanitized to #{sanitized_phone_number}")
			user.update!(phone_number: sanitized_phone_number)
		end

		def sanitized_phone_number
			@sanitized_phone_number ||= begin
				sanitized = phone_number.tr('^0-9', '')
				log(level: :debug, msg: "Sanitized phone number to: #{sanitized}. Given: #{sanitized.length} Expected? #{EXPECTED_LENGTH} ")
				sanitized.length == EXPECTED_LENGTH ? sanitized : nil
			end
		end

		def validate!
			raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User
			raise "Expected phone_number to be a String. Received #{phone_number.class}" unless phone_number.is_a? String
		end
	end
end
