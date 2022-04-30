module RailsBase::ServiceLogging
	def log(level:, msg:)
	  logger.public_send(level, aletered_message(msg))
	rescue StandardError
		Rails.logger.public_send(level, aletered_message(msg))
	end

	def aletered_message(msg)
		"#{log_prefix}: #{msg}"
	end

	def logger
		defined?(context) ? context.logger : Rails.logger
	end

	def log_prefix
	  "[#{class_name}-#{service_id}]"
	end

	def class_name
		self.class.name
	end

	def service_id
	  @service_id ||= SecureRandom.alphanumeric(10)
	end
end
