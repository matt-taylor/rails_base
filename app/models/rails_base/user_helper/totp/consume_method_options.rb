# frozen_string_literal: true

require "rqrcode"

module RailsBase
  module UserHelper
    module Totp
      module ConsumeMethodOptions
        def persist_otp_metadata!
          reload # Ensure the user is relaoded to grab use the correct dat for the secret
          metadata = otp_metadata(safe: true, use_existing_temp: true)

          self.otp_secret = self.otp_secret || self.temp_otp_secret
          self.temp_otp_secret = nil
          self.otp_required_for_login = true
          save!
        end

        def otp_provisioning_uri(options = {})
          label = options.delete(:label) || "#{RailsBase.app_name}:#{self.email}"
          otp_secret = options[:otp_secret] || self.otp_secret

          ROTP::TOTP.new(otp_secret, options).provisioning_uri(label)
        end

        def otp_metadata(safe: false, use_existing_temp: false)
          secret ||= self.otp_secret
          secret ||= self.temp_otp_secret if safe && use_existing_temp
          secret ||= temporary_otp! if safe

          uri = otp_provisioning_uri({ otp_secret: secret })
          { secret: secret, uri: uri, qr_code: qr_code(uri) }
        end

        protected

        def qr_code(uri)
          qrcode = RQRCode::QRCode.new(uri)
          qrcode.as_svg(
            color: "000",
            shape_rendering: "crispEdges",
            module_size: 4,
            standalone: true,
            use_path: true
          )
        end

        def temporary_otp!(otp_secret_length = RailsBase.config.totp.secret_code_length)
          otp_secret = User.generate_otp_secret(otp_secret_length)

          self.temp_otp_secret = otp_secret
          save!

          otp_secret
        end
      end
    end
  end
end

