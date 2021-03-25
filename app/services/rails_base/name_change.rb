require 'velocity_limiter'

class RailsBase::NameChange < RailsBase::ServiceBase
	include VelocityLimiter
	include RailsBase::UserFieldValidators
	include ActionView::Helpers::DateHelper

	delegate :first_name, to: :context
	delegate :last_name, to: :context
	delegate :current_user, to: :context

	def call
		velocity = velocity_limit_reached?
		if velocity[:reached]
			context.fail!(message: velocity[:msg])
		end

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

		context.name_change = current_user.reload.full_name

		RailsBase::EmailVerificationMailer.event(
			user: current_user,
			event: "Succesfull name change to #{current_user.full_name}"
		).deliver_now
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
