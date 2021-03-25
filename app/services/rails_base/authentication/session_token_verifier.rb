require 'json'

module RailsBase::Authentication
	class SessionTokenVerifier < RailsBase::ServiceBase
		delegate :mfa_randomized_token, to: :context
		delegate :purpose, to: :context

		def call
			if mfa_randomized_token.nil?
				context.fail!(message: "Authorization token not present. Please Log in")
			end

			decoded = RailsBase::Encryption.decode(value: mfa_randomized_token, purpose: purpose || Constants::MSET_PURPOSE)
			if decoded.nil?
				context.fail!(message: "Authorization token has expired. Please Log in")
			end

			begin
				json_decoded = JSON.parse(decoded)
			rescue StandardError => e
				log(level: :fatal, msg: "Json parse error. [#{decoded}] could not be parsed.")
				context.fail!(message: "Authorization token has failed. Please Log in")
			end

			log(level: :info, msg: "Decoded message: #{json_decoded}")

			context.user_id = json_decoded['user_id']
			context.expires_at = json_decoded['expires_at']
		end
	end
end
