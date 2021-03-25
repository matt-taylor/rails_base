class RailsBase::EventMailer < RailsBase::ApplicationMailer
  default from: Rails.configuration.mail_from

  def send_sso(user:, message:)
    @user = user
    @message = message
    mail(to: user.email, subject: "#{Rails.application.class.parent_name}: SSO login", template_name: 'event')
    # event(user: user, event: 'SSO login', message: message)
  end

  def event(user:, event:, message:)
    @user = user
    @message = message
    mail(to: @user.email, subject: "#{Rails.application.class.parent_name}: #{event}", template_name: 'event')
  end
end
