module RailsBase::Authentication
	class MfaSetEncryptToken < RailsBase::ServiceBase
		delegate :user, to: :context
		delegate :expires_at, to: :context
		delegate :purpose, to: :context

		def call
			params = {
				value: value,
				purpose: purpose || Constants::MSET_PURPOSE,
				expires_at: expires_at
			}

			context.encrypted_val = RailsBase::Encryption.encode(params)
		end

		def value
			# user_id with the same expires_at will return the same Encryption token
			# to overcome this, do 2 things
			# 1: Rotate the secret on every boot (ensures tplem changes on semi regular basis)
			# 2: Add rand strings to the hash -- Ensures the token is different every time
			{ user_id: user.id, rand: rand.to_s, expires_at: expires_at }.to_json
		end

		def validate!
			raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User

			time_class = ActiveSupport::TimeWithZone
			raise "Expected expires_at to be a Received #{time_class}. Received #{expires_at.class}" unless expires_at.is_a? time_class
		end
	end
end
