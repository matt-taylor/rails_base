require 'velocity_limiter'

class RailsBase::NameChange < RailsBase::ServiceBase
	include VelocityLimiter
	include RailsBase::UserFieldValidators
	include ActionView::Helpers::DateHelper

	delegate :first_name, to: :context
	delegate :last_name, to: :context
	delegate :current_user, to: :context
	delegate :admin_user_id, to: :context

	def call
		if admin_user_id
			log(level: :warn, msg: "ADMIN CHANGE: initiated by user:#{admin_user_id}")
		else
			velocity = velocity_limit_reached?
			if velocity[:reached]
				context.fail!(message: velocity[:msg])
			end
		end

		original_name = current_user.full_name

		name_validation = validate_full_name?(first_name: first_name, last_name: last_name)

		unless name_validation[:status]
			errors = name_validation[:errors].values.join('</br>')
			context.fail!(message: errors)
		end

		log(level: :info, msg: "Modifying [#{current_user.id}] first name: #{current_user.first_name} -> #{first_name}}")
		log(level: :info, msg: "Modifying [#{current_user.id}] last name: #{current_user.last_name} -> #{last_name}}")

		if !current_user.update(first_name: first_name, last_name: last_name)
			context.fail!(message: "Unable to update name. Please try again later")
		end
		context.original_name = original_name
		context.name_change = current_user.reload.full_name

		return if admin_user_id

		RailsBase::EmailVerificationMailer.event(
			current_user,
			"Succesfull name change",
			"We changed the name on your account from #{original_name} to #{context.name_change}."
		).deliver_me
	end

	def velocity_max_in_frame
		1.hour
	end

	def velocity_max
		5
	end

	def velocity_frame
		5.hours
	end

	def cache_key
		"us.name_change.#{current_user.id}"
	end

	def validate!
		raise "Expected first_name to be a String. Received #{first_name.class}" unless first_name.is_a? String
		raise "Expected last_name to be a String. Received #{last_name.class}" unless last_name.is_a? String
		raise "Expected current_user to be a User. Received #{current_user.class}" unless current_user.is_a? User
	end
end
