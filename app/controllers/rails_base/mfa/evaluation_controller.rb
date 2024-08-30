# frozen_string_literal: true

module RailsBase::Mfa
  class EvaluationController < RailsBaseApplicationController
    before_action :validate_mfa_token!, only: [:mfa_evaluate, :validate_mfa_evaluation]
    before_action :authenticate_user!, only: [:mfa_evaluate_authenticated]
    OTP_TEMPLATE = "rails_base/mfa/validate/totp/totp_login_input"
    SMS_TEMPLATE = "rails_base/mfa/validate/sms/sms_login_input"

    # User is not expected to be logged in yet
    # GET mfa/evaluation
    def mfa_evaluate
      user = User.find(@token_verifier.user_id)
      decision = RailsBase::Mfa::Decision.(user: user)
      mfa_type = mfa_decision(provided: params[:type], default: decision.mfa_type, allowed: decision.mfa_options)

      @masked_phone = user.masked_phone
      @mfa_options = decision.mfa_options.map do |type|
        next if type == mfa_type

        {
          text: "Switch MFA to #{type}",
          ** RailsBase::Mfa.mfa_link(mfa: type)
        }
      end.compact

      case mfa_type
      when RailsBase::Mfa::OTP
        render OTP_TEMPLATE
      when RailsBase::Mfa::SMS
        render SMS_TEMPLATE
      end
    end

    # User is not expected to be logged in yet
    # POST mfa/evaluation
    def validate_mfa_evaluation
    end

    # GET mfa/evaluation/verify
    def mfa_evaluate_authenticated
    end

    # POST mfa/evaluation/verify
    def validate_mfa_evaluation_authenticated
    end

    private

    def mfa_decision(provided:, default:, allowed:)
      # Nothing was provided by the user
      return default if provided.nil?

      # Provided input is an allowed type for the current user
      return provided.to_sym if allowed.include?(provided.to_sym)

      # Provided input was not allowed
      # Assign the flash accordingly
      if flash[:alert].nil? || session[:mfa_evauluate_stopper]
        flash[:alert] = "Unknown MFA type #{provided}. Using #{default} instead"
      else
        session[:mfa_evauluate_stopper] = true
        flash[:alert] += " -- Unknown MFA type #{provided}. Using #{default} instead"
      end

      return default
    end
  end
end
