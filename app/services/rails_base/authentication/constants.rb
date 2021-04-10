module RailsBase::Authentication
	module Constants
		# Shared
		URL_HELPER = RailsBase.url_routes
		BASE_URL = Rails.configuration._custom_base_url
		BASE_URL_PORT = Rails.configuration._custom_base_url_port
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
		MP_MIN_LENGTH = 7
		MP_MIN_NUMS = 1
		MP_MIN_ALPHA = 6
		var = []
		var << "contain at least #{MP_MIN_NUMS} numerics [0-9]" if MP_MIN_NUMS > 0
		var << "contain at least #{MP_MIN_ALPHA} letters [a-z,A-Z]" if MP_MIN_NUMS > 0
		MP_REQ_MESSAGE = "Password must #{var.join(' and ')}. Minimum length is #{MP_MIN_LENGTH} and contain [1-9a-zA-Z] only"

		STATIC_WAIT_FLASH = '"Check email inbox for verification email. Follow instructions to gain access"'

		# SSO LOGIN Reason
		SSO_LOGIN_REASON = 'sso_login_data'

		ADMIN_REMEMBER_REASON = 'current_admin_user'
		ADMIN_REMEMBER_USERID_KEY = 'admin_remember_me_via_coco'
		ADMIN_MAX_IDLE_TIME = 3.minutes
	end
end
