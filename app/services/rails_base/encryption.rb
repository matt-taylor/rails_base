require 'securerandom'

class RailsBase::Encryption
  SECRET_NAME = 'encryption_service_verifier'
  extend RailsBase::ServiceLogging

  class << self
    # for service_logging class override
    def class_name
      name
    end
    # token = Encryption.encode(value: 'testing Encryption', purpose: :login)
    def encode(value:, purpose:, expires_in: nil, expires_at: nil, url_safe: false)
      # expires_in = 5.minutes if purpose==:user_id_ajax
      params = {}
      params[:purpose] = purpose if purpose

      params[:expires_at] = expires_at if expires_at

      # expires_in takes precedence
      if expires_in
        params[:expires_in] = expires_in
        params.delete :expires_at if expires_at
      end

      raise "expires_at && expires_in are both nil" if expires_in.nil? && expires_at.nil?

      log(level: :info, msg: "Encoding [#{value}] with params #{params}")
      token = verifier.generate(value, params)
      token = CGI.escape(token) if url_safe
      token
    end

    # decoded = Encryption.decode(value: token, purpose: :login)
    def decode(value:, purpose:, url_safe: false)
      value = CGI.unescape(value) if url_safe
      params = {}
      params[:purpose] = purpose if purpose
      log(level: :info, msg: "Decoding [#{value}] with params #{params}")
      # TODO: matt-taylor
      # Check if the message is valid and untampered with
      # https://api.rubyonrails.org/classes/ActiveSupport/MessageVerifier.html#method-i-valid_message-3F
      decoded = verifier.verified(value, params)
      if decoded.nil?
        log(level: :warn, msg: "Failed to decode value: value: #{value}, purpose: #{purpose}")
      end
      decoded
    end

    # Encryption.rotate_secret
    def rotate_secret
      if old_secret
        verifier(force: true).rotate(old_secret)
      else
        verifier(force: true)
      end
      log(level: :info, msg: "Rotating secret for Encryption")
    end

    private

    def verifier(force: false)
      if force
        @verifier = ActiveSupport::MessageVerifier.new(next_secret, digest: 'SHA512')
      end
      @verifier ||= ActiveSupport::MessageVerifier.new(current_secret, digest: 'SHA512')
    end

    def old_secret
      Secret.get_secret_range(name: SECRET_NAME)&.first&.secret
    end

    def current_secret
      Secret.get_current_secret(name: SECRET_NAME)&.secret || next_secret
    end

    def next_secret
      secret = Secret.update(name: SECRET_NAME, secret: generate_secret)

      secret.secret
    end

    def generate_secret
      SecureRandom.hex[0..16]
    end
  end
end
