# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    phone_number  { Faker::PhoneNumber.phone_number }
    password { Faker::Alphanumeric.alpha(number: 20) }
    password_confirmation { password }
    email_validated { true }
    email { Faker::Internet.email }

    trait :unvalidated_email do
      email_validated { false }
    end

    trait :sms_enabled do
      mfa_sms_enabled { true }
    end

    trait :totp_enabled do
      temp_otp_secret { nil }
      otp_secret { User.generate_otp_secret }

      otp_backup_codes { User.generate_backup_codes }
      mfa_otp_enabled { true }
    end

    trait :temp_totp_enabled do
      temp_otp_secret { User.generate_otp_secret }
      otp_secret { nil }

      otp_backup_codes { [] }
      mfa_otp_enabled { true }
    end
  end
end
