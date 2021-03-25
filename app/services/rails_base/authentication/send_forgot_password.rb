module RailsBase::Authentication
	class SendForgotPassword < RailsBase::ServiceBase
		delegate :email, to: :context

		def call
			user = User.find_for_authentication(email: email)

			if user.nil?
				log(level: :warn, msg: "Failed to find email assocaited to #{email}. Not sending email")
				context.fail!(message: "Failed to send forget password to #{email}", redirect_url: '')
			end
			email_send = SendVerificationEmail.call(user: user, reason: Constants::VFP_REASON)

			if email_send.failure?
				log(level: :error, msg: "Failed to send forget password: #{email_send.message}")
				context.fail!(message: email_send.message, redirect_url: '/')
			end

			context.message = 'You should receive an email shortly.'
		end

		def validate!
			raise "Expected email to be a String. Received #{email.class}" unless email.is_a? String
		end
	end
end
