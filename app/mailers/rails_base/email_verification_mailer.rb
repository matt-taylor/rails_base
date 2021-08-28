class RailsBase::EmailVerificationMailer < RailsBase::ApplicationMailer
	default from: Rails.configuration.mail_from

	def email_verification(user:, url:)
	  @user = user
	  @sso_url_for_user = url
	  mail(to: @user.email, subject: "Welcome to #{RailsBase.app_name}")
	end

	def forgot_password(user:, url:)
	  @user = user
	  @sso_url_for_user = url
	  mail(to: @user.email, subject: "#{RailsBase.app_name}: Forgot Password")
	end

	def event(user:, event:, msg: nil)
	  @user = user
	  @event = event
	  @msg = msg
	  mail(to: @user.email, subject: "#{RailsBase.app_name}: #{event}")
	end
end
