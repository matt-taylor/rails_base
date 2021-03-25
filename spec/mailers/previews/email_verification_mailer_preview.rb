# Preview all emails at http://localhost:3000/rails/mailers/email_verification_mailer
class RailsBase::EmailVerificationMailerPreview < ActionMailer::Preview
  def email_verification
    url = 'http://www.thisIsAFakeDomain.org'
    RailsBase::EmailVerificationMailer.email_verification(user: User.first, url: url)
  end

  def forgot_password
    url = 'http://www.thisIsAFakeDomain.org'
    RailsBase::EmailVerificationMailer.forgot_password(user: User.first, url: url)
  end
end
