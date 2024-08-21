# frozen_string_literal: true

require "rqrcode"

module RailsBase
  module UserHelper
    module Totp
      module ConsumeMethodOptions
        def enable_totp_for_user!
          totp_enabled!
        end

        def persist_otp_metadata!
          metadata = otp_metadata(safe: true)
          self.otp_secret = self.otp_secret || self.temp_otp_secret
          self.temp_otp_secret = nil
          self.otp_required_for_login = true
          save!
        end

        def totp_enabled!
          raise Error, "TOTP is not enabled for application" unless totp_config.enable?
          raise NotRequired, "TOTP is not required for user" unless self.otp_required_for_login # default is set to false

          true
        end

        def totp_config
          RailsBase.config.totp
        end

        def validate_and_consume_otp!(code, options = {})
          bypass_require = options.delete(:bypass_require)
          totp_enabled! if bypass_require.nil?

          otp_secret = options[:otp_secret] || self.otp_secret
          return false unless code.present? && otp_secret.present?

          totp = otp(otp_secret, bypass_require)

          if self.consumed_timestep
            # reconstruct the timestamp of the last consumed timestep
            after_timestamp = self.consumed_timestep * totp.interval
          end

          if totp.verify(code.gsub(/\s+/, ""), drift_behind: self.class.totp_drift_behind, drift_ahead: self.class.totp_drift_ahead, after: after_timestamp)
            return consume_otp!(totp.interval, bypass_require)
          end

          false
        end

        def otp(otp_secret = self.otp_secret, bypass = false)
          totp_enabled! unless bypass

          ROTP::TOTP.new(otp_secret)
        end

        def current_otp
          totp_enabled!

          otp.at(Time.now)
        end

        def otp_provisioning_uri(options = {})
          label = options.delete(:label) || "#{RailsBase.app_name}:#{self.email}"
          otp_secret = options[:otp_secret] || self.otp_secret

          totp_enabled! if otp_secret.nil?

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
          otp_secret = ::User.generate_otp_secret(otp_secret_length)

          self.temp_otp_secret = otp_secret
          save!

          otp_secret
        end

        # An OTP cannot be used more than once in a given timestep
        # Storing timestep of last valid OTP is sufficient to satisfy this requirement
        def consume_otp!(interval, bypass = false)
          totp_enabled! unless bypass

          timestep = Time.now.utc.to_i / interval
          if self.consumed_timestep != timestep
            self.consumed_timestep = timestep
            return save(validate: false)
          end

          false
        end
      end
    end
  end
end

