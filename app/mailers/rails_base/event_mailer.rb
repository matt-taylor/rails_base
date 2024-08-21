class RailsBase::EventMailer < RailsBase::ApplicationMailer
  default from: Rails.configuration.mail_from

  def send_sso(user, message)
    @user = user
    @message = message
    mail(to: user.email, subject: "#{RailsBase.app_name}: SSO login", template_name: 'event')
    # event(user: user, event: 'SSO login', message: message)
  end

  def event(user, event, message)
    @user = user
    @message = message
    mail(to: @user.email, subject: "#{RailsBase.app_name}: #{event}", template_name: 'event')
  end

  include ::RailsBase::MailerKwargInject
end
