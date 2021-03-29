module RailsBase::Authentication
  class DestroyUser < RailsBase::ServiceBase
    delegate :current_user, to: :context
    delegate :data, to: :context

    include RailsBase::UserSettingsHelper

    def call
      datum = get_short_lived_datum(data)
      validate_datum?(datum)
      # sign_out(current_user)
      destroy_user!
    end

    def destroy_user!
      log(level: :warn, msg: "Destroying user: #{current_user.id}")

      # delete the user
      current_user.soft_destroy_user!
    end

    def validate_datum?(datum)
      return true if datum[:valid]

      if datum[:found]
        msg = "Errors with Destroy User token: #{datum[:invalid_reason].join(", ")}. Please try again"
        log(level: :warn, msg: msg)
        context.fail!(message: msg)
      end

      log(level: :warn, msg: "Could not find datum code. User may be doing Fishyyyyy things")

      context.fail!(message: "Invalid Data Code. Please retry action")
    end

    def get_short_lived_datum(data)
      ShortLivedData.find_datum(data: data, reason: DATUM_REASON)
    end

    def validate!
      raise "Expected data to be a String. Received #{data.class}" unless data.is_a? String
      raise "Expected current_user to be a User. Received #{current_user.class}" unless current_user.is_a? User
    end
  end
end
