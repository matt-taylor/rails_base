class RailsBase::ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.configuration.action_mailer.smtp_settings[:user_name] }
  layout 'mailer'

  CONTACT_URL = [
      RailsBase.config.app.base_url,
      RailsBase.config.app.base_port,
    ].compact.join(':')
end
