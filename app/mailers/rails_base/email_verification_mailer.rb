class RailsBase::EmailVerificationMailer < RailsBase::ApplicationMailer
	default from: Rails.configuration.mail_from

	def email_verification(user:, url:)
	  @user = user
	  @sso_url_for_user = url
	  mail(to: @user.email, subject: "Welcome to #{Rails.application.class.parent_name}")
	end

	def forgot_password(user:, url:)
	  @user = user
	  @sso_url_for_user = url
	  mail(to: @user.email, subject: "#{Rails.application.class.parent_name}: Forgot Password")
	end

	def event(user:, event:)
	  @user = user

	  mail(to: @user.email, subject: "#{Rails.application.class.parent_name}: #{event}")
	end
end
