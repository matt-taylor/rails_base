module RailsBase::ServiceLogging
	def log(level:, msg:)
	  altered_message = "#{log_prefix}: #{msg}"
	  logger.public_send(level, altered_message)
	rescue StandardError
		Rails.logger.public_send(level, msg)
	end

	def logger
		defined?(context) ? context.loger : nil
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
