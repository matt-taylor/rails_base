# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::Validate::TotpController, type: :controller do
  let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, expires_at: 5.minutes.from_now).encrypted_val }
  let(:session) { { mfa_randomized_token: mfa_randomized_token } }
  let(:user) { create(:user, :totp_enabled)}


  before { @request.env["devise.mapping"] = Devise.mappings[:user] }
  describe "#GET totp_login_input" do
    subject(:totp_login_input) { get(:totp_login_input, session:) }

    context "with invalid mfa token" do
      let(:mfa_randomized_token) { "Invalid MFA token" }

      context "when user signed in" do
        before { sign_in(user) }
        it do
          totp_login_input

          expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
        end
      end

      it do
        totp_login_input

        expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
      end
    end

    it do
      totp_login_input

      expect(response).to render_template(:totp_login_input)
    end
  end

  describe "#POST totp_login" do
    subject(:totp_login_input) { post(:totp_login, session:, params:) }

    let(:params) { { totp_code: } }
    let(:totp_code) { ROTP::TOTP.new(user.otp_secret).at(Time.now) }

    context "with invalid mfa token" do
      let(:mfa_randomized_token) { "Invalid MFA token" }

      context "when user signed in" do
        before { sign_in(user) }
        it do
          totp_login_input

          expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
        end
      end

      it do
        totp_login_input

        expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
      end
    end

    context "with incorrect otp code" do
      let(:totp_code) { "12345" }

      it do
        totp_login_input

        expect(response).to redirect_to(RailsBase.url_routes.mfa_evaluation_path(type: RailsBase::Mfa::OTP))
      end

      it do
        totp_login_input

        expect(flash[:alert]).to include("Invalid TOTP code")
      end
    end

    it "signs in user" do
      totp_login_input

      expect(user_signed_in?).to be(true)
    end

    it do
      totp_login_input

      expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
    end
  end
end
