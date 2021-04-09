####################################################
# File is prepended with 01 so that it loads first #
####################################################

require 'link_decision_helper'

Rails.application.configure do
  ###################
  # Redis variables #
  ###################
  # if not set downstream, send the email
  unless (config.redis_url_admin_action rescue false)
    config.redis_url_admin_action = ENV['REDIS_URL']
  end

  unless (config.redis_namespace_admin_action rescue false)
    config.redis_namespace_admin_action = nil
  end

  #######################
  # Twilio Requirements #
  #######################
  config.twilio_sid = ENV.fetch('TWILIO_ACCOUNT_SID')
  config.twilio_auth_token = ENV.fetch('TWILIO_AUTH_TOKEN')
  config.twilio_from_number = ENV.fetch('TWILIO_FROM_NUMBER')

  ###################################################################
  # Twilio velocity requirements - protection from calling too much #
  ###################################################################
  config.twilio_velocity_max = ENV.fetch('TWILIO_VELOCITY_MAX', 5).to_i # max inside of time frame
  config.twilio_velocity_max_in_frame = ENV.fetch('TWILIO_VELOCITY_MAX_IN_FRAME', 1).to_i # time frame for max
  config.twilio_velocity_frame = ENV.fetch('TWILIO_VELOCITY_FRAME', 5).to_i # TTL for key -- for dubuggging/history

  #################################################
  # Allow custom exceptions app for 404, 422, 500 #
  #################################################
  config.exceptions_app = self.routes

  #########################
  # Configure Mail client #
  #########################
  # Note: If using GMAIL, app password is different
  # Follow instructions: https://support.google.com/accounts/answer/185833?hl=en
  config.mail_from = ENV.fetch('GMAIL_USER_NAME')

  # if not set downstream, send the email
  unless config.action_mailer.delivery_method
    config.action_mailer.delivery_method = :smtp
  end

  config.action_mailer.default_options = { from: ENV.fetch('GMAIL_USER_NAME') }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    :address              => "smtp.gmail.com",
    :port                 => 587,
    :user_name            => ENV.fetch('GMAIL_USER_NAME'),
    :password             => ENV.fetch('GMAIL_PASSWORD'),
    :authentication       => "plain",
    :enable_starttls_auto => true
  }

  #######################
  # Define external url #
  #######################
  config._custom_base_url = ENV.fetch('BASE_URL', 'http://localhost')
  config._custom_base_url_port = ENV.fetch('BASE_URL_PORT', nil)

  ######################
  # Configure timeouts #
  ######################
  session_timeout = ENV['SESSION_TIMEOUT_IN_SECONDS']
  session_timeout =
    if session_timeout
      (session_timeout.to_i > 0) ? session_timeout.to_i.seconds : 60.days
    end

  # session timout set for devise and for forced logout via ajax; when nil, there is no timeout
  config.session_timeout = session_timeout
  # show timout warning for user
  config.session_timeout_warning = (ENV['SESSION_TIMEOUT_WARNING'] == 'true')
  # max time allowed between mfa authentication
  config.mfa_time_duration = 1.day

  ############################################
  # Explicitly set RailsBase mailer location #
  ############################################
  config.action_mailer.preview_path = RailsBase::Engine.root.join('spec','mailers','previews')

  ###############################
  # load assets from rails base #
  ###############################
  config.assets.precompile << 'rails_base/manifest'


  #################################
  # Define logged in Header paths #
  #################################
  LinkDecisionHelper::ALLOWED_TYPES.each do |type|
    thing = config.public_send("#{type}||=", [])
    if thing.empty?
      admin_url_proc = -> { RailsBase.url_routes.admin_base_path }
      default = LinkDecisionHelper.new(title: nil, url: nil, type: type, default_type: type, config: config)
      admin = LinkDecisionHelper.new(title: 'Admin', url: admin_url_proc, type: type, config: config)
      config.public_send("#{type}=", [default, admin])
    end
  end
end
