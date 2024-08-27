module RailsBase::Authentication
	class VerifyForgotPassword < RailsBase::ServiceBase
		delegate :data, to: :context

		def call
			mfa_flow = false
			data_point = short_lived_data
			validate_datum?(data_point)

			log(level: :info, msg: "Validated user 2fa email #{data_point[:user].full_name}")
			context.user = data_point[:user]
			context.encrypted_val =
				MfaSetEncryptToken.call(user: data_point[:user], expires_at: Time.zone.now + 10.minutes, purpose: Constants::VFP_PURPOSE).encrypted_val
			return unless data_point[:user].mfa_sms_enabled

			result = SendLoginMfaToUser.call(user: data_point[:user], expires_at: Time.zone.now + 10.minutes)
			if result.failure?
				log(level: :warn, msg: "Attempted to send MFA to user from #{self.class.name}: Exiting with #{result.message}")
				context.fail!(message: result.message, redirect_url: Constants::URL_HELPER.new_user_password_path, level: :warn)
			end
			context.mfa_flow = true
		end

		def validate_datum?(datum)
			return true if datum[:valid]

			if datum[:found]
				msg = "Errors with email validation: #{datum[:invalid_reason].join(", ")}. Please go through forget password flow again."
				log(level: :warn, msg: msg)
				context.fail!(message: msg, redirect_url: Constants::URL_HELPER.new_user_password_path, level: :warn)
			end

			log(level: :warn, msg: "Could not find MFA code. Incorrect MFA code. User is doing something fishy.")

			context.fail!(message: Constants::MV_FISHY, redirect_url: Constants::URL_HELPER.authenticated_root_path, level: :warn)
		end

		def short_lived_data
			ShortLivedData.find_datum(data: data, reason: Constants::VFP_REASON)
		end

		def validate!
			raise "Expected data to be a String. Received #{data.class}" unless data.is_a? String
		end
	end
end
