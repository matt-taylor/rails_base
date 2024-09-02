# frozen_string_literal: true

module RailsBase::Mfa::Validate
  class SmsController < RailsBaseApplicationController
    before_action :validate_mfa_with_event!, only: [:sms_event_input, :sms_event]

    # POST mfa/validate/sms/:mfa_event/send
    def sms_event_send
      if soft_mfa_with_event
        user = User.find(@__rails_base_mfa_event.user_id)
      else
        if request.format.json?
          render json: { message: @__rails_base_mfa_event_invalid_reason }, status: 400
        else
          flash[:alert] = @__rails_base_mfa_event_invalid_reason
          redirect = @__rails_base_mfa_event&.invalid_redirect || RailsBase.url_routes.new_user_session_path

          redirect_to redirect, email: params.dig(:user,:email)
        end
        return
      end

      if request.format.json?
        # When json, this will always come from an authenticated user
        # otherwise kick them out now!
        return unless authenticate_user!

        user = current_user
      end

      result = RailsBase::Mfa::Sms::Send.call(expires_at: 5.minutes.from_now, phone_number: @__rails_base_mfa_event.phone_number, user: user)

      if result.success?
        flash[:notice] = msg = "SMS Code succesfully sent. Please check messages"
        status = 200
      else
        flash[:alert] = msg = "Unable to complete Request. #{result.message}"
        status = 400
      end

      if request.format.json?
        render json: { message: msg }, status: status
        flash.clear
      else
        redirect_to RailsBase.url_routes.mfa_with_event_path(mfa_event: @__rails_base_mfa_event.event, type: RailsBase::Mfa::SMS)
      end
    end

    # GET mfa/validate/sms/:mfa_event
    def sms_event_input
      if @__rails_base_mfa_event.phone_number
        phone_number = @__rails_base_mfa_event.phone_number
      else
        phone_number = User.find(@__rails_base_mfa_event.user_id).phone_number
      end

      @masked_phone = User.masked_number(phone_number)
    end

    # POST mfa/validate/sms/:mfa_event
    def sms_event
      mfa_validity = RailsBase::Mfa::Sms::Validate.call(mfa_event: @__rails_base_mfa_event, params: params, session_mfa_user_id: @__rails_base_mfa_event.user_id)
      if mfa_validity.failure?
        redirect_to(mfa_validity.redirect_url, alert: mfa_validity.message)
        return
      end

      mfa_validity.user.set_last_mfa_sms_login!
      if @__rails_base_mfa_event.sign_in_user
        logger.info("Logging User in")
        sign_in(mfa_validity.user)
      end

      if @__rails_base_mfa_event.set_satiated_on_success
        logger.info("Satiating MFA Event")
        @__rails_base_mfa_event.satiated!
      end

      add_mfa_event_to_session(event: @__rails_base_mfa_event)
      redirect_to @__rails_base_mfa_event.redirect, notice: @__rails_base_mfa_event.flash_notice
    end
  end
end
