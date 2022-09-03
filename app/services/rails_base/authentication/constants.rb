module RailsBase::Authentication
	module Constants
		# Shared
		URL_HELPER = RailsBase.url_routes
		BASE_URL = RailsBase.config.app.base_url
		BASE_URL_PORT = RailsBase.config.app.base_port
		MFA_REASON = :two_factor_mfa_code
		MFA_LENGTH = RailsBase.config.mfa.mfa_length
		EMAIL_LENGTH = 255 # MAX LENGTH we can insert into mysql

		MIN_NAME = 2
		MAX_NAME = 25
		NAME_VALIDATION = "Must be #{MIN_NAME} to #{MAX_NAME} in length. Can contain characters [a-zA-Z ']"

		# verify forgot password
		VFP_PURPOSE = :forgot_password_flow
		VFP_REASON = :email_sso_forgot_password

		# mfa set encrypt token
		MSET_PURPOSE = :mfa_session_token

		# send login mfa to user
		SLMTU_TTL = (5.minutes + 30.seconds)

		# send verification email
		SVE_TTL = 1.hour || 7.minutes
		SVE_LOGIN_REASON = :email_sso_login_verify
		SVE_FORGOT_REASON = :email_sso_forgot_password

		# mfa validator
		MV_BASE_NAME = 'mfa_pos_'
		MV_FISHY = 'Kicked back to login. You are doing something fishy.'

		# sso verifiy email
		SSOVE_PURPOSE = :verify_email

		# modify password
		MP_MIN_LENGTH = RailsBase.config.auth.password_min_length
		MP_MIN_NUMS = RailsBase.config.auth.password_min_numeric
		MP_MIN_ALPHA = RailsBase.config.auth.password_min_alpha
		MP_REQ_MESSAGE = RailsBase.config.auth.password_message

		STATIC_WAIT_FLASH = '"Check email inbox for verification email. Follow instructions to gain access"'

		# SSO LOGIN Reason
		SSO_LOGIN_REASON = 'sso_login_data'

		ADMIN_REMEMBER_REASON = 'current_admin_user'
		ADMIN_REMEMBER_USERID_KEY = 'admin_remember_me_via_coco'
		ADMIN_MAX_IDLE_TIME = 3.minutes

		SSO_SEND_LENGTH = 64
		SSO_SEND_USES = 2
		SSO_REASON = :sending_sso_to_user
		SSO_EXPIRES = 2.hours
	end
end
