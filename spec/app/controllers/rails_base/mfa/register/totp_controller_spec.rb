# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::Register::TotpController, type: :controller do

  before do
    sign_in(user)
  end

  describe "#DELETE totp_remove" do
    subject(:totp_remove) { delete(:totp_remove, params:) }

    let(:user) { create(:user, :totp_enabled, password:) }
    let(:params) do
      {
        password: input_password,
        totp_code:,
      }
    end
    let(:password) { "password123" }
    let(:input_password) { password }
    let(:totp_code) { ROTP::TOTP.new(user.otp_secret).at(Time.now) }

    context "when removal fails" do
      context "with incorrect password" do
        let(:input_password) { "12345" }

        it do
          totp_remove

          expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
        end

        it do
          totp_remove

          expect(flash[:alert]).to include("Something Went Wrong")
        end
      end

      context "with incorrect totp_code" do
        let(:totp_code) { "12345" }

        it do
          totp_remove

          expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
        end

        it do
          totp_remove

          expect(flash[:alert]).to include("Something Went Wrong")
        end
      end
    end

    it do
      totp_remove

      expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
    end

    it do
      totp_remove

      expect(flash[:notice]).to include("Successfully Removed TOTP Authentication")
    end
  end

  describe "#POST totp_secret" do
    subject(:totp_secret) { post(:totp_secret) }

    let(:user) { create(:user) }

    context "when otp_metadata fails" do
      before do
        allow(RailsBase::Mfa::Totp::OtpMetadata).to receive(:call).with(anything).and_return(instance)
      end

      let(:instance) { double("RailsBase::Mfa::Totp::OtpMetadata", message: "no", failure?: true, success?: false) }

      it do
        totp_secret

        expect(response.body).to include("status")
      end

      it do
        totp_secret

        expect(response.status).to eq(400)
      end
    end

    it do
      totp_secret

      expect(response.body).to include("secret")
    end

    it do
      totp_secret

      expect(response.status).to eq(200)
    end
  end

  describe "#POST totp_validate" do
    subject(:totp_validate) { post(:totp_validate, params: {totp_code:}) }

    let(:user) { create(:user, :totp_enabled) }
    let(:totp_code) { ROTP::TOTP.new(user.otp_secret).at(Time.now) }

    context "with incorrect code" do
      let(:totp_code) { "1234" }

      it do
        totp_validate

        expect(flash[:alert]).to include("Something Went Wrong")
      end

      it do
        totp_validate

        expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
      end
    end

    it do
      totp_validate

      expect(flash[:notice]).to include("Successfully added an Authenticator")
    end

    it do
      totp_validate

      expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
    end
  end
end
