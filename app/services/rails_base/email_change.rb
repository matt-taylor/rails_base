require 'velocity_limiter'

class RailsBase::EmailChange < RailsBase::ServiceBase
  include VelocityLimiter
  include RailsBase::UserFieldValidators
  include ActionView::Helpers::DateHelper

  delegate :email, to: :context
  delegate :last_name, to: :context
  delegate :user, to: :context

  def call
    context.original_email = user.email
    user.update_attribute(:email, email)
    context.new_email = email
    log(level: :info, msg: "Changed #{user.id} email from: #{context.original_email} to #{email}")
  rescue StandardError
    context.fail!(message: 'Unable to update email address. Likely that this email is already taken')
  end

  def deliver_email
    RailsBase::EmailVerificationMailer.event(
      user: current_user,
      event: "Succesfull email change",
      msg: "We changed the name on your account from #{original_name} to #{context.name_change}."
    ).deliver_now
  end

  def validate!
    raise "Expected email to be a String. Received #{email.class}" unless email.is_a? String
    raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User
  end
end
