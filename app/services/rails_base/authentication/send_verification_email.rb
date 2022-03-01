require 'velocity_limiter'

module RailsBase::Authentication
	class SendVerificationEmail < RailsBase::ServiceBase
		include ActionView::Helpers::DateHelper
		include VelocityLimiter

		delegate :user, to: :context
		delegate :reason, to: :context

		DATA_USE = :alphanumeric
		VELOCITY_MAX = 5
		VELOCITY_MAX_IN_FRAME = 10.minutes
		VELOCITY_FRAME = 1.hour

		REASON_MAPPER = {
			Constants::SVE_LOGIN_REASON => {
				method: :email_verification,
				url_method: :email_verification_url,
				max_use: RailsBase.config.login_behavior.email_max_use_verification
			},
			Constants::SVE_FORGOT_REASON => {
				method: :forgot_password,
				url_method: :forgot_password_auth_url,
				max_use: RailsBase.config.login_behavior.email_max_use_forgot
			}
		}

		def call
			velocity = velocity_limit_reached?
			if velocity[:reached]
				context.fail!(message: velocity[:msg])
			end

			data_point = create_short_lived_data
			begin
				url = assign_url(data_point.data)
			rescue StandardError => e
				log(level: :error, msg: "Error: #{e.class}")
				log(level: :error, msg: "Error: #{e.message}")
				log(level: :error, msg: "Failed to get url for #{url_method}")
				log(level: :error, msg: "Swallowing Error. Returning to user")
				context.fail!(message: "Unknown error occurred. Please log in with credentials to restart process")
				return
			end
			log(level: :info, msg: "SSO url for user #{user.id}: #{url}")

			begin
				RailsBase::EmailVerificationMailer.public_send(method, user: user, url: url).deliver_me
			rescue StandardError => e
				log(level: :error, msg: "Unkown error occured when sending EmailVerificationMailer.#{method}")
				log(level: :error, msg: "Params: #{method}, #{reason}, user: #{user.id}")
				context.fail!(message: "Unknown error occurred. Please log in with credentials to restart process")
				return
			end
			log(level: :info, msg: "Succesfully sent EmailVerificationMailer.#{method} to #{user.id} @ #{user.email}")
		end

		def assign_url(data)
			params = {
				data: data,
				host: Constants::BASE_URL,
			}
			params[:port] = Constants::BASE_URL_PORT if Constants::BASE_URL_PORT
			Constants::URL_HELPER.public_send(url_method, params)
		end

		def create_short_lived_data
			params = {
				user: user,
				max_use: REASON_MAPPER[reason][:max_use],
				reason: reason,
				data_use: DATA_USE,
				ttl: Constants::SVE_TTL,
				length: Constants::EMAIL_LENGTH,
			}
			ShortLivedData.create_data_key(**params)
		end

		def velocity_max_in_frame
			VELOCITY_MAX_IN_FRAME
		end

		def velocity_max
			VELOCITY_MAX
		end

		def velocity_frame
			VELOCITY_FRAME
		end

		def cache_key
			"#{self.class.name.downcase}.#{user.id}"
		end

		def method
			REASON_MAPPER[reason][:method]
		end

		def url_method
			REASON_MAPPER[reason][:url_method]
		end

		def validate!
			raise "Expected user to be a User. Received #{user.class}" unless user.is_a? User
			raise "Expected reason to be a symbol. Received #{reason.class}" unless reason.is_a? Symbol
			raise "Expected #{reason} to be in #{REASON_MAPPER.keys}" unless REASON_MAPPER.keys.include?(reason)
		end
	end
end
