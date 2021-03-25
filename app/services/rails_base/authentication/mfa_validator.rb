module RailsBase::Authentication
	class MfaValidator < RailsBase::ServiceBase
		delegate :params, to: :context
		delegate :session_mfa_user_id, to: :context
		delegate :current_user, to: :context

		def call
			array = convert_to_array
			if array.length != Constants::MFA_LENGTH
				log(level: :warn, msg: "Not enough params for MFA code. Given #{array}. Expected of length #{Constants::MFA_LENGTH}")
				context.fail!(message: Constants::MV_FISHY, redirect_url: Constants::URL_HELPER.new_user_session_path, level: :alert)
			end

			mfa_code = array.join
			log(level: :info, msg: "mfa code received: #{mfa_code}")
			datum = get_short_lived_datum(mfa_code)
			log(level: :info, msg: "Datum returned with: #{datum}")

			validate_datum?(datum)
			validate_user_consistency?(datum)
			validate_current_user?(datum) if current_user

			context.user = datum[:user]
		end

		def validate_current_user?(datum)
			return true if current_user.id == datum[:user].id

			# User MFA for a different user matched the session token
			# However, those did not match the current user signed in
			# Something is very 🐟
			log(level: :error, msg: "Someone is a teapot. Current logged in user does not equal mfa code.")
			context.fail!(message: 'You are a teapot', redirect_url: Constants::URL_HELPER.signout_path, level: :warn)
		end

		def validate_datum?(datum)
			return true if datum[:valid]

			if datum[:found]
				# MFA is either expired or the incorrect reason. Either way it does not match
				msg = "Errors with MFA: #{datum[:invalid_reason].join(", ")}. Please login again"
				log(level: :warn, msg: msg)
				context.fail!(message: msg, redirect_url: Constants::URL_HELPER.new_user_session_path, level: :warn)
			end

			# MFA does not exist for any reason type
			log(level: :warn, msg: "Could not find MFA code. Incorrect MFA code")

			context.fail!(message: "Incorrect MFA code.", redirect_url: Constants::URL_HELPER.mfa_code_path, level: :warn)
		end

		def validate_user_consistency?(datum)
			return true if datum[:user].id == session_mfa_user_id.to_i
			log(level: :warn, msg: "Datum user does not match session user. [#{datum[:user].id}, #{session_mfa_user_id.to_i}]")

			# MFA session token user does not match the datum user
			# Something is very 🐟
			context.fail!(message: Constants::MV_FISHY, redirect_url: Constants::URL_HELPER.new_user_session_path, level: :alert)
		end

		def get_short_lived_datum(mfa_code)
			log(level: :debug, msg: "Looking for #{mfa_code} with reason #{Constants::MFA_REASON}")
			ShortLivedData.find_datum(data: mfa_code, reason: Constants::MFA_REASON)
		end

		def convert_to_array
			array = []
			return array unless params.dig(:mfa).respond_to? :keys

			Constants::MFA_LENGTH.times do |index|
				var_name = "#{Constants::MV_BASE_NAME}#{index}".to_sym
				array << params[:mfa][var_name]
			end

			array.compact
		end

		def validate!
			raise 'Expected the params passed' if params.nil?
			raise 'session_mfa_user_id is not present' if session_mfa_user_id.nil?
		end
	end
end
