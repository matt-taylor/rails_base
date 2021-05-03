class RailsBase::ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'

  CONTACT_URL = [
      RailsBase.config.app.base_url,
      RailsBase.config.app.base_port,
    ].compact.join(':')
end
