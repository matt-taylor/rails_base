module RailsBase::UserFieldValidators
	# allows us to use standard functionality of logging shit
	def self.included klass
    klass.class_eval do
      include RailsBase::ServiceLogging
    end
  end

  def validate_complement?(user_params:)
		status = { status: true, errors: {} }
  	if user_params[:first_name]
	  	validator = validate_name?(name: user_params[:first_name])
	  	unless validator[:status]
	  		status[:status] = false
	  		status[:errors][:first_name] = "First Name validation: #{validator[:msg]}"
	  	end
  	end

  	if user_params[:last_name]
	  	validator = validate_name?(name: user_params[:last_name])
	  	unless validator[:status]
	  		status[:status] = false
	  		status[:errors][:last_name] = "Last Name validation: #{validator[:msg]}"
	  	end
  	end

  	if user_params[:password] && user_params[:password_confirmation]
  		validator = validate_password?(password: user_params[:password], password_confirmation: user_params[:password_confirmation])
  		unless validator[:status]
  			status[:status] = false
  			status[:errors][:password] = "Password validation: #{validator[:msg]}"
  		end
  	end
  	status
  end

  def validate_full_name?(first_name:, last_name:)
    status = { status: true, errors: {} }
    if first_name
      validator = validate_name?(name: first_name)
      unless validator[:status]
        status[:status] = false
        status[:errors][:first_name] = "First Name validation: #{validator[:msg]}"
      end
    end

    if last_name
      validator = validate_name?(name: last_name)
      unless validator[:status]
        status[:status] = false
        status[:errors][:last_name] = "Last Name validation: #{validator[:msg]}"
      end
    end
    status
  end

  def validate_name?(name:)
  	unacceptable_chars = name.tr("a-zA-Z '",'')
  	if unacceptable_chars.length > 0
			log(level: :warn, msg: "name #{name} contains unacceptable_chars [#{unacceptable_chars}]")
			return { status: false, msg: "Value can not contain #{unacceptable_chars}" }
  	end

    if name.length > RailsBase::Authentication::Constants::MAX_NAME
      log(level: :warn, msg: "name #{name} contains too many characters. Max allowed is #{RailsBase::Authentication::Constants::MAX_NAME}")
      return { status: false, msg: "Too many characters. Max allowed is #{RailsBase::Authentication::Constants::MAX_NAME}" }
    end

    if name.length < RailsBase::Authentication::Constants::MIN_NAME
      log(level: :warn, msg: "name #{name} contains too few characters. MIN allowed is #{RailsBase::Authentication::Constants::MIN_NAME}")
      return { status: false, msg: "Too few characters. Max allowed is #{RailsBase::Authentication::Constants::MIN_NAME}" }
    end
		{ status: true }
  end

	def validate_password?(password:, password_confirmation:)
		if password != password_confirmation
			log(level: :warn, msg: 'User password inputs do not match. Must retry flow')
			return { status: false, msg: 'Passwords do not match. Retry password flow' }
		end

		if password.length < RailsBase::Authentication::Constants::MP_MIN_LENGTH
			log(level: :warn, msg: RailsBase::Authentication::Constants::MP_REQ_MESSAGE)
			return { status: false, msg: RailsBase::Authentication::Constants::MP_REQ_MESSAGE }
		end

		number_count = password.scan(/\d/).join('').length
		char_count = password.scan(/[a-zA-Z]/).join('').length
		non_standard_chars = password.scan(/\W/)

		if char_count < RailsBase::Authentication::Constants::MP_MIN_ALPHA
			log(level: :warn, msg: "User password does not have enough numbers. Req: #{RailsBase::Authentication::Constants::MP_MIN_ALPHA}. Given: #{char_count}")
			return { status: false, msg: "Password must contain at least #{RailsBase::Authentication::Constants::MP_MIN_ALPHA} characters [a-z,A-Z]" }
		end

		if number_count < RailsBase::Authentication::Constants::MP_MIN_NUMS
			log(level: :warn, msg: "User password does not have enough numbers. Req: #{RailsBase::Authentication::Constants::MP_MIN_NUMS}. Given: #{number_count}")
			return { status: false, msg: "Password must contain at least #{RailsBase::Authentication::Constants::MP_MIN_NUMS} numbers [0-9]" }
		end

    unacceptable_chars = non_standard_chars - RailsBase.config.auth.password_allowed_special_chars.split("")
		if unacceptable_chars.length > 0
			log(level: :warn, msg: "User password contains unacceptable_chars special chars. Received: #{unacceptable_chars}")
			return { status: false, msg: "Unaccepted characters received. Characters must be in [0-9a-zA-Z] and [#{RailsBase.config.auth.password_allowed_special_chars}] exclusively. Received #{unacceptable_chars}" }
		end

		{ status: true }
	end
end
