module RailsBase::Authentication
	class VerifyForgotPassword < RailsBase::ServiceBase
		delegate :data, to: :context

		def call
			mfa_flow = false
			data_point = short_lived_data
			validate_datum?(data_point)

			log(level: :info, msg: "Validated user 2fa email #{data_point[:user].full_name}")

			context.user = data_point[:user]
			mfa_decision = RailsBase::Mfa::Decision.(force_mfa: true, user: data_point[:user])

			if context.mfa_flow = mfa_decision.mfa_require
				log(level: :info, msg: "User has #{mfa_decision.mfa_options} mfa options enabled. MFA is required to reset password")
			else
				log(level: :info, msg: "User has no MFA options enabled. MFA is NOT required to reset password")
			end
		end

		def validate_datum?(datum)
			return true if datum[:valid]

			if datum[:found]
				msg = "Errors with email validation: #{datum[:invalid_reason].join(", ")}. Please go through forget password flow again."
				log(level: :warn, msg: msg)
				context.fail!(message: msg, redirect_url: Constants::URL_HELPER.new_user_password_path, level: :warn)
			end

			log(level: :warn, msg: "Could not find MFA code. Incorrect MFA code. User is doing something fishy.")

			context.fail!(message: Constants::MV_FISHY, redirect_url: Constants::URL_HELPER.unauthenticated_root_path, level: :warn)
		end

		def short_lived_data
			ShortLivedData.find_datum(data: data, reason: Constants::VFP_REASON)
		end

		def validate!
			raise "Expected data to be a String. Received #{data.class}" unless data.is_a? String
		end
	end
end
