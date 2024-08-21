# frozen_string_literal: true

module RailsBase
  module UserHelper
    module Totp
      module BackupMethodOptions
        def generate_otp_backup_codes!
          codes = []
          number_of_codes = totp_config.backup_code_count
          code_length = totp_config.backup_code_length

          number_of_codes.times do
            codes << SecureRandom.hex(code_length / 2) # Hexstring has length 2*n
          end

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
