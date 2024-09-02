# frozen_string_literal: true

module RailsBase::Authentication
	class SsoVerifyEmail < RailsBase::ServiceBase
		delegate :verification, to: :context

		def call
			datum = get_short_lived_datum(verification)
			validate_datum?(datum)

			user = datum[:user]
			user.update(email_validated: true)

			context.user = datum[:user]
			params = {
				expires_at: Time.zone.now + Constants::SVE_TTL,
				user: user,
				purpose: Constants::SSOVE_PURPOSE
			}
			context.encrypted_val = RailsBase::Mfa::EncryptToken.(params).encrypted_val
		end

		def validate_datum?(datum)
			return true if datum[:valid]

			if datum[:found]
				msg = "Errors with Email Verification: #{datum[:invalid_reason].join(", ")}. Please login again"
				log(level: :warn, msg: msg)
				context.fail!(message: msg, redirect_url: Constants::URL_HELPER.new_user_session_path, level: :warn)
			end

			log(level: :warn, msg: "Could not find MFA code. Incorrect Email verification code. User may be doing Fishyyyyy things")

			context.fail!(message: "Invalid Email Verification Code. Log in again.", redirect_url: Constants::URL_HELPER.new_user_session_path, level: :warn)
		end

		def get_short_lived_datum(mfa_code)
			ShortLivedData.find_datum(data: mfa_code, reason: Constants::SVE_LOGIN_REASON)
		end

		def validate!
			raise "verification is expected" if verification.nil?
		end
	end
end
