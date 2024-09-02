# frozen_string_literal: true

module RailsBase::Mfa::Validate
  class TotpController < RailsBaseApplicationController
    before_action :validate_mfa_with_event!

    # GET mfa/validate/totp/:event
    def totp_event_input; end

    # POST mfa/validate/totp/:event
    def totp_event
      user = User.find(@__rails_base_mfa_event.user_id)
      mfa_validity = ::RailsBase::Mfa::Totp::ValidateCode.(user: user, otp_code: params[:totp_code])
      if mfa_validity.failure?
        redirect_to(RailsBase.url_routes.mfa_with_event_path(mfa_event: @__rails_base_mfa_event.event, type: RailsBase::Mfa::OTP), alert: mfa_validity.message)
        return
      end

      user.set_last_mfa_otp_login!

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
