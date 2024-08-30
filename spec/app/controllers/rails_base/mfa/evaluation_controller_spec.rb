# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::EvaluationController, type: :controller do
  let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, expires_at: 5.minutes.from_now).encrypted_val }
  let(:session_input) { { mfa_randomized_token: mfa_randomized_token } }

  describe "# GET mfa_evaluate" do
    subject(:mfa_evaluate) { get(:mfa_evaluate, params:, session: session_input) }

    let(:params) { {} }

    context "with invalid user" do
      let(:mfa_randomized_token) { "Invalid mfa token" }

      it do
        mfa_evaluate

        expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
      end

      it do
        mfa_evaluate

        expect(flash[:alert]).to include("Authorization token has expired")
      end
    end

    context "with no param" do
      context "when totp only" do
        let(:user) { create(:user, :totp_enabled) }

        it do
          mfa_evaluate

          expect(response).to render_template(described_class::OTP_TEMPLATE)
        end
      end

      context "when sms only" do
        let(:user) { create(:user, :sms_enabled) }

        it do
          mfa_evaluate

          expect(response).to render_template(described_class::SMS_TEMPLATE)
        end
      end

      context "when totp and sms" do
        let(:user) { create(:user, :totp_enabled, :sms_enabled) }

        it do
          mfa_evaluate

          expect(response).to render_template(described_class::OTP_TEMPLATE)
        end
      end
    end

    context "with allowed param" do
      let(:user) { create(:user, :totp_enabled, :sms_enabled) }

      context "with sms" do
        let(:params) { super().merge(type: RailsBase::Mfa::SMS.to_s) }

        it do
          mfa_evaluate

          expect(response).to render_template(described_class::SMS_TEMPLATE)
        end
      end

      context "with totp" do
        let(:params) { super().merge(type: RailsBase::Mfa::OTP.to_s) }

        it do
          mfa_evaluate

          expect(response).to render_template(described_class::OTP_TEMPLATE)
        end
      end
    end

    context "with disallowed param" do
      context "with sms" do
        let(:user) { create(:user, :totp_enabled) }
        let(:params) { super().merge(type: RailsBase::Mfa::SMS.to_s) }

        it do
          mfa_evaluate

          expect(response).to render_template(described_class::OTP_TEMPLATE)
        end

        it "correct alert when called multiple times" do
          flash[:alert] = "something"
          expect(session[:mfa_evauluate_stopper]).to be_nil

          get(:mfa_evaluate, params:, session: session_input, flash: { alert: "something" })
          expect(response).to render_template(described_class::OTP_TEMPLATE)
          expect(flash[:alert]).to include("something")
          expect(flash[:alert]).to include("-- Unknown MFA type")
          expect(session[:mfa_evauluate_stopper]).to eq(true)

          get(:mfa_evaluate, params:, session: session_input, flash: { alert: "something" })
          expect(response).to render_template(described_class::OTP_TEMPLATE)
          expect(flash[:alert]).to_not include("something")
          expect(flash[:alert]).to include("Unknown MFA type")
        end
      end

      context "with totp" do
        let(:user) { create(:user, :sms_enabled) }
        let(:params) { super().merge(type: RailsBase::Mfa::OTP.to_s) }

        it do
          mfa_evaluate

          expect(response).to render_template(described_class::SMS_TEMPLATE)
        end

        it "correct alert when called multiple times" do
          flash[:alert] = "something"
          expect(session[:mfa_evauluate_stopper]).to be_nil

          get(:mfa_evaluate, params:, session: session_input, flash: { alert: "something" })
          expect(response).to render_template(described_class::SMS_TEMPLATE)
          expect(flash[:alert]).to include("something")
          expect(flash[:alert]).to include("-- Unknown MFA type")
          expect(session[:mfa_evauluate_stopper]).to eq(true)

          get(:mfa_evaluate, params:, session: session_input, flash: { alert: "something" })
          expect(response).to render_template(described_class::SMS_TEMPLATE)
          expect(flash[:alert]).to_not include("something")
          expect(flash[:alert]).to include("Unknown MFA type")
        end
      end

    end
  end
end
