####################################################
# File is prepended with 01 so that it loads first #
####################################################

require 'link_decision_helper'

Rails.application.configure do
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
    thing = config.public_send("#{type} ||=", [])
    config.public_send("#{type}=", []) if thing.empty?
  end
end
