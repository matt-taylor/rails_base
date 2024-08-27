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
				return
			end

			mfa_decision = RailsBase::Mfa::Decision.(user: user)
			check_success!(result: mfa_decision)

			case mfa_decision.mfa_type
			when RailsBase::Mfa::SMS
			when RailsBase::Mfa::OTP
			when RailsBase::Mfa::NONE
				# no MFA type enabled on account
				sign_in_user_context!
				context.flash = { notice: "Welcome. You have succesfully signed in. We suggest enabling 2fa authentication to secure your account" }

			else
				raise "Unknown MFA type provided"
			end

			mfa_decision =
				if user.email_validated
					if RailsBase.config.mfa.enable? && user.mfa_sms_enabled
						sms_enabled_context!(decision: mfa_decision)
					else
						# user has signed up and validated email
						# user does not have mfa enabled
						sign_in_user_context!
						context.flash = { notice: "Welcome. You have succesfully signed in. We suggest enabling 2fa authentication to secure your account" }
						nil
					end
				end

			if mfa_decision && mfa_decision.failure?
				log(level: :error, msg: "Service error bubbled up. Failing with: #{mfa_decision.message}")
				context.fail!(message: mfa_decision.message)
			end

			log(level: :info, msg: "User #{user.id}: redirect_url: #{context.redirect_url}, sign_in_user: #{context.sign_in_user}, flash: #{context.flash}")
		end

		def check_success!(result:)
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

		def sms_enabled_context!(decision:)
			if decision.mfa_require
				log(level: :warn, msg: "SMS MFA required for user")
				context.redirect_url = Constants::URL_HELPER.sms_validate_login_input_path
				context.set_mfa_randomized_token = true
				context.mfa_purpose = nil # use default
				context.flash = { notice: "Please check your mobile device. We sent an SMS for MFA verification" }
				result = RailsBase::Mfa::Sms::Send.call(user: user)
				context.token_ttl = result.short_lived_data.death_time if result.success?
				result
			else
				sign_in_user_context!
				mfa_free_words = distance_of_time_in_words(user.last_mfa_sms_login, User.time_bound)
				context.flash = { notice: "Welcome. You have succesfully signed in. You will be mfa free for another #{mfa_free_words}" }
				log(level: :info, msg: "User is mfa free for another #{mfa_free_words}")
				nil
			end
		end

		def validate!
			raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User
		end
	end
end
