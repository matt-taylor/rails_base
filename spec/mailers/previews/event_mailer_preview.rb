# Preview all emails at http://localhost:3000/rails/mailers/email_verification_mailer
class RailsBase::EventMailerPreview < ActionMailer::Preview
  def send_sso
    message = 'Hello. There is probably some really important link in here'
    RailsBase::EventMailer.send_sso(user: User.first, message: message)
  end
end
