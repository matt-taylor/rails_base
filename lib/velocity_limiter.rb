module VelocityLimiter
	def velocity_limit_reached?
		_velocity_limiter_params_validator!

		metadata = vl_metadata

		log(level: :info, msg: "#{cache_key} has attempted #{self.class.name} #{metadata[:within_attempts_count]} times since #{metadata[:threshold]}")

		if metadata[:velocity_reached]
			log(level: :warn, msg: "#{cache_key} has been velocity limited. #{metadata[:within_attempts_count]} attempts since #{metadata[:threshold]}. MAX allowed is #{velocity_max}")
			log(level: :warn, msg: "#{cache_key} may try again in #{metadata[:to_words]} :: #{metadata[:attempt_again_at]}. Will fully reset at #{metadata[:fully_reset_time]}")
			msg = "Velocity limit reached for SMS verification. You may try again in #{metadata[:to_words]}"
			return {reached: true, msg: msg}
		end

		vl_write!(metadata[:vl_write])

		{ reached: false }
	end

	def _velocity_limiter_params_validator!
		raise "Parent overloaded velocity_max_in_frame. Expected to be a ActiveSupport::Duration" unless velocity_max_in_frame.is_a? ActiveSupport::Duration
		raise "Parent overloaded velocity_frame. Expected to be a ActiveSupport::Duration" unless velocity_frame.is_a? ActiveSupport::Duration
		raise "Parent overloaded velocity_max. Expected to be a Integer" unless velocity_max.is_a? Integer
		raise "Parent overloaded velocity_max. Expected to be a Integer greater than 1" if velocity_max < 1
		raise "Parent overloaded cache_key. Expected to be a String" unless cache_key.is_a? String
	end

	def velocity_max_in_frame
	end

	def velocity_max
	end

	def velocity_frame
	end

	def cache_delineator
		','
	end

	def vl_time
		@vl_time ||= Time.zone.now
	end

	def vl_metadata(vl_arr: vl_read)
		threshold = vl_time - velocity_max_in_frame
		within_attempts = vl_arr.select do |time|
			time >= threshold
		end
		attempt_again_at = within_attempts.first ? (within_attempts.first + velocity_max_in_frame) : Time.zone.now

		obj = {}
		obj[:vl_write] = [within_attempts, vl_time].flatten
		obj[:fully_reset_time] = (within_attempts.last || Time.zone.now) + velocity_max_in_frame
		obj[:attempt_again_at] = attempt_again_at
		obj[:velocity_reached] = within_attempts.count >= velocity_max
		obj[:within_attempts_arr] = within_attempts
		obj[:within_attempts_count] = within_attempts.count
		obj[:threshold] = threshold
		obj[:velocity_max] = velocity_max
		obj[:velocity_frame] = velocity_frame
		obj[:velocity_max_in_frame] = velocity_max_in_frame
		obj[:to_words] = distance_of_time_in_words(Time.zone.now, attempt_again_at, include_seconds: true)

		obj
	end

	def vl_read
		json = Rails.cache.fetch(cache_key) || ''
		begin
			array = json.split(cache_delineator).map { |time| Time.zone.parse time }
		rescue StandardError => e
			log(level: :error, msg: "Failed to parse json strings into time. #{json}")
			array = []
		end
		log(level: :info, msg: "Read from #{cache_key} :: #{array}")

		array
	end

	def vl_write!(write)
		cache_write = write.map(&:to_s).join(cache_delineator)
		log(level: :info, msg: "Writing [#{cache_write}] to #{cache_key}")
		Rails.cache.write(cache_key, cache_write, expires_in: velocity_frame)
	end

	def cache_key
		raise "cache_key must be defined in the parent class"
	end
end
