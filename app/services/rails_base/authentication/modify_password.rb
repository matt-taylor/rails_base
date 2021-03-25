module RailsBase::Authentication
	class ModifyPassword < RailsBase::ServiceBase
		include RailsBase::UserFieldValidators

		delegate :password, to: :context
		delegate :password_confirmation, to: :context
		delegate :data, to: :context # the same datum used in the reset password url
		delegate :user_id, to: :context
		delegate :flow, to: :context
		delegate :current_user, to: :context

		FLOW_TYPES = [:forgot_password, :user_settings]

		def call
			valid_password = validate_password?(password: password, password_confirmation: password_confirmation)
			unless valid_password[:status]
				context.fail!(message: valid_password[:msg])
			end

			if user.nil?
				log(level: :error, msg: "Could not find [#{user_id}]. 5xx error with user deletion most likely")
				context.fail!(message: "Unknown error. Please try again")
			end

			case flow
			when :forgot_password
				forgot_password
			else
			end

			unless user.update(password: password, password_confirmation: password_confirmation)
				context.fail!(message: "Failed to update user. Please try again")
			end
			log(level: :info, msg: "Successfully update users password")
		end

		def forgot_password
			return if  valid_short_term_data_point?

			context.fail!(message: Constants::MV_FISHY)
		end

		def valid_short_term_data_point?
			raise 'Expected data to be defined' if data.nil?

			data_point = ShortLivedData.get_by_data(data: data, reason: Constants::VFP_REASON)
			datum_user_id = data_point&.user_id

			log(level: :info, msg: "Found ShortLivedData with data #{data[0..15]}... attached to user [#{datum_user_id}]")

			datum_user_id && (datum_user_id.to_i == user_id.to_i)
		end

		def user
			@user ||= current_user || User.find_by_id(user_id)
		end

		def validate!
			raise "Expected Flow to be present and a Symbol" unless flow.is_a? Symbol
			raise "Expected Flow to be in #{FLOW_TYPES}" unless FLOW_TYPES.include?(flow)
			raise "Expected password to be a String. Received #{password.class}" unless password.is_a? String
			raise "Expected password_confirmation to be a String. Received #{password_confirmation.class}" unless password_confirmation.is_a? String
			raise "Expected user_id to be present." if current_user.nil? && user_id.nil?
			raise "Expected data to be present." if current_user.nil? && data.nil?
		end
	end
end
