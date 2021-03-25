class RailsBase::ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'

  CONTACT_URL = [
      Rails.configuration._custom_base_url,
      Rails.configuration._custom_base_url_port
    ].compact.join(':')
end
