# frozen_string_literal: true

module RailsBase
  module UserHelper
    module Totp
      module BackupMethodOptions
        def generate_otp_backup_codes!
          codes = User.generate_backup_codes
          self.otp_backup_codes = codes
          save!

          codes
        end

        def invalidate_otp_backup_code!(code)
          codes = self.otp_backup_codes || []

          return false unless codes.include?(code)

          codes.delete(code)

          self.otp_backup_codes = codes

          save!
        end

        def totp_config
          RailsBase.config.totp
        end
      end
    end
  end
end
