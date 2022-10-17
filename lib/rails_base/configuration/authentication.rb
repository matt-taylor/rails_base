require 'rails_base/configuration/base'

module RailsBase
  module Configuration
    class Authentication < Base
      DEFAULT_SESSION = 60.days
      MIN_SESSION = 5.minutes

      DEFAULT_MFA_TIME = 7.day
      MIN_MFA_TIME = 1.day
      PASSWORD_MIN_LENGTH = 8
      PASSWORD_MIN_NUMERIC = 2
      PASSWORD_MIN_ALPHANUMERIC = 6
      PASSWORD_ALLOWED_SPECIAL_CHARS = "(),.\"'{}[]!@\#$%^&*_-+="

      PASSWORD_MESSAGE_ON_ASSIGNMENT = Proc.new do |value, current|
        if value.nil?
          special_chars_str =
            if current.password_allowed_special_chars.nil?
              "No Special characters are allowed"
            else
              "Only the following special characters are allowed #{current.password_allowed_special_chars}"
            end

          current.password_message = "Password must be at least #{current.password_min_length} characters long. " \
            "With #{current.password_min_numeric} numbers [0-9] and #{current.password_min_alpha} letters [a-zA-Z]. " \
            "#{special_chars_str}."
        end
      end

      DEFAULT_VALUES = {
        session_timeout: {
          type: :duration,
          default: ENV.fetch('SESSION_TIMEOUT_IN_SECONDS', DEFAULT_SESSION).to_i.seconds,
          custom: ->(val) { val.to_i >= MIN_SESSION },
          msg: "session_timeout must be a duration. Greater than #{MIN_SESSION}",
          on_assignment: ->(val, _instance) { Devise.timeout_in = val },
          description: 'Debug purposes. How long to keep admin_velocity_max attempts',
        },
        session_timeout_warning: {
          type: :boolean,
          default: true,
          description: 'Display a timeout warning. When disabled, user will be logged out without warning',
        },
        login_message_base: {
          type: :string_proc,
          default: ->(user) { "Welcome #{user.full_name}. You have succesfully signed in to #{RailsBase.config.app.app_name}" } ,
          description: 'Login Base message for all users when using user/password flow',
        },
        login_message_mfa_user_disabled: {
          type: :string_proc_nil,
          default: ->(user) { "We suggest enabling MFA authentication to secure your account" } ,
          description: 'Additive login message for when MFA is enabled and user MFA is disabled',
        },
        mfa_time_duration: {
          type: :duration,
          default: DEFAULT_MFA_TIME,
          custom: ->(val) { val.to_i > MIN_MFA_TIME },
          msg: "mfa_time_duration must be a duration. Greater than #{MIN_MFA_TIME}",
          description: 'Max time between when MFA will be required',
        },
        password_min_length: {
          type: :integer,
          default: PASSWORD_MIN_LENGTH,
          custom: ->(val) { val >= PASSWORD_MIN_LENGTH },
          msg: "password_min_length must be a integer greater than #{PASSWORD_MIN_LENGTH}.",
          description: 'Min length the password can be.',
        },
        password_min_numeric: {
          type: :integer,
          default: PASSWORD_MIN_NUMERIC,
          custom: ->(val) { val >= PASSWORD_MIN_NUMERIC },
          msg: "password_min_numeric must be a integer greater or equal to #{PASSWORD_MIN_NUMERIC}.",
          description: 'Min count of numerics in password.',
        },
        password_min_alpha: {
          type: :integer,
          default: PASSWORD_MIN_ALPHANUMERIC,
          custom: ->(val) { val >= PASSWORD_MIN_ALPHANUMERIC },
          msg: "password_min_alpha must be a integer greater or equal to #{PASSWORD_MIN_ALPHANUMERIC}.",
          description: 'Min count of letters in password.',
        },
        password_allowed_special_chars: {
          type: :string_nil,
          default: PASSWORD_ALLOWED_SPECIAL_CHARS,
          description: 'Allowed special characters in password.',
        },
        password_message: {
          type: :string_nil,
          default: nil,
          description: 'Password message for users.',
          on_assignment: PASSWORD_MESSAGE_ON_ASSIGNMENT,
        }
      }
      attr_accessor *DEFAULT_VALUES.keys

      private

      def custom_validations
        enforce_password_config!
      end

      def enforce_password_config!
        incorrectness = []
        incorrectness << "`password_min_numeric` is not less than or equal to `password_min_length`" if password_min_numeric <= password_min_length
      end
    end
  end
end
