module RailsBase::Authentication
	class DecisionTwofaType < RailsBase::ServiceBase
		delegate :user, to: :context

	  include ActionView::Helpers::DateHelper

		def call
			# default return values
			context.set_mfa_randomized_token = false
			context.sign_in_user = false
			unless user.email_validated
				email_context = validate_email_context!
				check_success!(result: email_context)
				log(level: :info, msg: "User #{user.id}: redirect_url: #{context.redirect_url}, sign_in_user: #{context.sign_in_user}, flash: #{context.flash}")
				log_exit
				return
			end

			unless RailsBase.config.mfa.enable?
				log(level: :info, msg: "MFA on app is not enabled. Bypassing")
				sign_in_user_context!
				context.flash = { notice: "Welcome. You have succesfully signed in." }
				log_exit
				return
			end

			mfa_decision = RailsBase::Mfa::Decision.(user: user)
			check_success!(result: mfa_decision)
			mfa_type_result = nil
			case mfa_decision.mfa_type
			when RailsBase::Mfa::SMS
				mfa_type_result = sms_enabled_context!(decision: mfa_decision)
			when RailsBase::Mfa::OTP
				totp_enabled_context!(decision: mfa_decision)
			when RailsBase::Mfa::NONE
				# no MFA type enabled on account
				sign_in_user_context!
				context.flash = { notice: "Welcome. You have succesfully signed in." }
				context.session = { add_mfa_button: true }
			else
				raise "Unknown MFA type provided"
			end
			check_success!(result: mfa_type_result)
			log_exit
		end

		def log_exit
			log(level: :info, msg: "User #{user.id}: redirect_url: #{context.redirect_url}, sign_in_user: #{context.sign_in_user}, flash: #{context.flash}")
		end

		def check_success!(result:)
			return if result.nil?
			return if result.success?

			log(level: :error, msg: "Service error bubbled up. Failing with: #{result.message}")
			context.fail!(message: result.message)
		end

		def validate_email_context!
			# user has signed up but have not validated their email
			context.redirect_url = Constants::URL_HELPER.auth_static_path
			context.set_mfa_randomized_token = true
			context.mfa_purpose = Constants::SSOVE_PURPOSE
			context.flash = { notice: Constants::STATIC_WAIT_FLASH }
			context.token_ttl = Time.zone.now + 5.minutes
			SendVerificationEmail.call(user: user, reason: Constants::SVE_LOGIN_REASON)
		end

		def sign_in_user_context!
			log(level: :warn, msg: "Will log in user #{user.id} and bypass 2fa")
			context.redirect_url = Constants::URL_HELPER.authenticated_root_path
			context.sign_in_user = true
		end

		def totp_enabled_context!(decision:)
			if decision.mfa_require
				log(level: :warn, msg: "TOTP MFA required for user")
				context.redirect_url = RailsBase.url_routes.mfa_evaluation_path
				context.set_mfa_randomized_token = true
				context.mfa_purpose = nil # use default
				context.flash = { notice: "Additional Verification requested" }
				context.token_ttl = 2.minutes.from_now
			else
				sign_in_user_context!
				context.flash = { notice: "Welcome. You have succesfully signed in via #{decision.mfa_type.to_s.upcase} MFA." }
				nil
			end
		end

		def sms_enabled_context!(decision:)
			if decision.mfa_require
				log(level: :warn, msg: "SMS MFA required for user")
				context.redirect_url = RailsBase.url_routes.mfa_evaluation_path
				context.set_mfa_randomized_token = true
				context.mfa_purpose = nil # use default
				context.flash = { notice: "Please check your mobile device. We sent an SMS for MFA verification" }
				result = RailsBase::Mfa::Sms::Send.call(user: user)
				context.token_ttl = result.short_lived_data.death_time if result.success?
				result
			else
				sign_in_user_context!
				context.flash = { notice: "Welcome. You have succesfully signed in via #{decision.mfa_type.to_s.upcase} MFA." }
				nil
			end
		end

		def validate!
			raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User
		end
	end
end
