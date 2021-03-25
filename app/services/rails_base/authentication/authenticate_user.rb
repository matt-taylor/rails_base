module RailsBase::Authentication
	class AuthenticateUser < RailsBase::ServiceBase
		delegate :email, to: :context
		delegate :password, to: :context
		delegate :current_user, to: :context

		def call
			user = current_user || User.find_for_authentication(email: email)
			valid = user.present? && user.valid_password?(password)
			if valid
				log(level: :info, msg: "Correctly found valid user_id #{user.id}")
				context.user = user
			else
				log(level: :warn, msg: "Failed to validate credentials")
				log(level: :warn, msg: "Found user? #{user.present?}. Valid password?[#{user&.valid_password?(password)}]")
				context.fail!(message: "Incorrect credentials. Please try again")
			end
		end

		def validate!
			raise "Expected email to be a String. Received #{email.class}" unless email.is_a? String
			raise "Expected password to be a String. Received #{password.class}" unless password.is_a? String

			return unless current_user
			raise "Expected current_user to be a User. Received #{current_user.class}" unless current_user.is_a? User
		end
	end
end
