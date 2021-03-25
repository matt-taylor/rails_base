module RailsBase::Authentication
	class DecisionTwofaType < RailsBase::ServiceBase
		delegate :user, to: :context

	  include ActionView::Helpers::DateHelper

		def call
			# default return values
			context.set_mfa_randomized_token = false
			context.sign_in_user = false

			mfa_decision =
				if user.email_validated
					if user.mfa_enabled
						mfa_enabled_context!
					else
						# user has signed up and validated email
						# user does not have mfa enabled
						sign_in_user_context!
						context.flash = { notice: "Welcome. You have succesfully signed in. We suggest enabling 2fa authentication to secure your account" }
						nil
					end
				else
					validate_email_context!
				end

			if mfa_decision && mfa_decision.failure?
				log(level: :error, msg: "Service error bubbled up. Failing with: #{mfa_decision.message}")
				context.fail!(message: mfa_decision.message)
			end

			log(level: :info, msg: "User #{user.id}: redirect_url: #{context.redirect_url}, sign_in_user: #{context.sign_in_user}, flash: #{context.flash}")
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

		def mfa_enabled_context!
			if user.past_mfa_time_duration?
				# user has signed up and validated email
				# user has mfa enabled
				log(level: :warn, msg: "User needs to go through mfa flow. #{user.last_mfa_login} < #{User.time_bound}")
				context.redirect_url = Constants::URL_HELPER.mfa_code_path
				context.set_mfa_randomized_token = true
				context.mfa_purpose = nil # use default
				context.flash = { notice: "Please check your mobile device. We sent an SMS for 2fa verification" }
				result = SendLoginMfaToUser.call(user: user)
				context.token_ttl = result.short_lived_data.death_time if result.success?
				result
			else
				sign_in_user_context!
				mfa_free_words = distance_of_time_in_words(user.last_mfa_login, User.time_bound)
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
