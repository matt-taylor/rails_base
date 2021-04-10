# config/initializers/rails_base_config.rb

##
# This is a file full of defaults.
# The values commend out are already defaults. Uncomment and change the values if you would like
##

RailsBase.configure do |config|
  #################################
  # Administrative configurations #
  #################################
  # Enable admin. This is the primary swtich to enable all admin capabilities
  # When disabled, no admin actions are available, including routes
  # config.admin.enable = true

  # Enable users to view history
  # `enable` is a dependent
  # config.admin.enable_history = true

  # Enable which users can view the admin page
  # Recomended only Admin Users as Admin actions will likely fail
  # `enable` is a dependent
  # config.admin.view_admin_page = ->(user) { user.active && user.admin_super? }

  # Enable which users can view history page
  # `enable_history` is a dependent
  # `enable` is a dependent
  # config.admin.enable_history_by_user = ->(user) { true }

  # Enable saving actions to database and showing for users which actions occured
  # `enable` is a dependent
  # config.admin.enable_actions = true

  # Max number of changes to ricky properties in the frame
  # config.admin.admin_velocity_max = ENV.fetch('ADMIN_VELOCITY_MAX', 20)

  # Window Frame to keep track of admin_velocity_max. This is a sliding window
  # config.admin.admin_velocity_max_in_frame = ENV.fetch('ADMIN_VELOCITY_MAX_IN_FRAME', 1).hours

  # Used for debug. Max time frame an admins details is stored in the cache
  # config.admin.admin_velocity_frame = ENV.fetch('ADMIN_VELOCITY_FRAME', 5).to_i.hours



  #################################
  # Authentication configurations #
  #################################
  # Time until a session is invalid. We then assign this to devise
  # config.auth.session_timeout = ENV.fetch('SESSION_TIMEOUT_IN_SECONDS', 60.days).to_i.seconds

  # Show the timeout warning modal. Without this we will log the user out without warning
  # With this, we will show a 1 minute warning before logging out
  # config.auth.session_timeout_warning = true

  # When MFA is enabled, this is the max time between MFA verifications
  # config.auth.mfa_time_duration = 7.day



  ######################
  # MFA configurations #
  ######################
  # Primary switch to control if MFa is enabled for the entire app
  # When disabled, users will not have the MFA flow. Admins will still need to
  # use MFA flow for risky changes
  # config.mfa.enable = ENV.fetch('MFA_ENABLE', 'true')=='true'

  # The length that MFA code will be. There are lenght constraints on this
  # config.mfa.mfa_length = 5

  # Twilio SID.
  # App will fail to boot if not present and mfa is enabled
  # config.mfa.twilio_sid = ENV.fetch('TWILIO_ACCOUNT_SID','')

  # Twilio Auth token.
  # App will fail to boot if not present and mfa is enabled
  # config.mfa.twilio_auth_token = ENV.fetch('TWILIO_AUTH_TOKEN', '')

  # Twilio From Phone number.
  # App will fail to boot if not present and mfa is enabled
  # config.mfa.twilio_from_number = ENV.fetch('TWILIO_FROM_NUMBER', ''


  # Max number of texts we will send to a user in a sliding time frame
  # config.mfa.twilio_velocity_max = ENV.fetch('TWILIO_VELOCITY_MAX', 5).to_i

  # Sliding window frame for max texts to send
  # config.mfa.twilio_velocity_max_in_frame = ENV.fetch('TWILIO_VELOCITY_MAX_IN_FRAME', 1).to_i.hours

  # Used for debug. Max time frame a users details is stored in the cache
  # config.mfa.twilio_velocity_frame = ENV.fetch('TWILIO_VELOCITY_FRAME', 5).to_i.hours



  ########################
  # Redis configurations #
  ########################
  # Redis Url for admin action cache
  # NOTE: If not enalbed but enable_actions is, we swallow errors, and no modal popup for users
  # config.mfa.admin_action = ENV.fetch('REDIS_URL','')

  # Redis Namespace for admin action cache
  # config.mfa.admin_action_namespace = nil
end




