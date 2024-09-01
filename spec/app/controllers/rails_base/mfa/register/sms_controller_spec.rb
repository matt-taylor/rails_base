# frozen_string_literal: true

require 'twilio_helper'

RSpec.describe RailsBase::Mfa::Register::SmsController, type: :controller do
  let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, expires_at: 5.minutes.from_now).encrypted_val }
  let(:user) { create(:user, phone_number: nil) }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  before do
    sign_in(user)
    allow(TwilioHelper).to receive(:send_sms)
  end

  describe "#POST sms_registration" do
    subject(:sms_registration) { post(:sms_registration, params: { phone_number: phone_number }, format: :json) }

    context "when phone update fails" do
      let(:phone_number) { "not a phone number" }

      it do
        sms_registration

        expect(response.body).to include("Unable to complete request")
      end

      it do
        sms_registration

        expect(response.status).to eq(418)
      end
    end

    it "sets mfa token" do
      expect(session[:mfa_randomized_token]).to be_nil

      sms_registration

      expect(session[:mfa_randomized_token]).to be_present
    end

    it do
      expect { sms_registration }.to change { user.reload.phone_number }.from(nil).to(phone_number.tr('^0-9', ''))
    end

    it do
      sms_registration

      expect(response.body).to include("You are not a teapot")
    end
  end

  describe "#POST sms_confirmation" do
    subject(:sms_confirmation) { post(:sms_confirmation, params:, session: mfa_event_session_hash(mfa_event:)) }

    let(:mfa_event) { RailsBase::MfaEvent.sms_enable(user:) }
    let(:datum) { RailsBase::Mfa::Sms::Send.new(user: user, expires_at: 5.minutes.from_now).create_short_lived_data }
    let(:mfa_code) { datum.data }
    let(:mfa_params) do
      _params = {}
      RailsBase::Authentication::Constants::MFA_LENGTH.times do |index|
        var_name = "#{RailsBase::Authentication::Constants::MV_BASE_NAME}#{index}".to_sym
        _params[var_name] = mfa_code.split('')[index]
      end
      _params
    end
    let(:params) { { mfa: mfa_params } }

    context "with invalid mfa event" do
      context "with invalid name" do
        let(:mfa_event) { RailsBase::MfaEvent.login_event(user:) }

        it do
          sms_confirmation

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          sms_confirmation

          expect(flash[:alert]).to include("Unauthorized MFA event")
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        it do
          sms_confirmation

          expect(flash[:alert]).to include("MFA event for #{mfa_event.event}")
        end

        it do
          sms_confirmation

          expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
        end
      end
    end

    context "with incorrect code" do
      before do
        key = mfa_params.keys.sample
        mfa_params[key] = "X"
      end

      it do
        sms_confirmation

        expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
      end

      it do
        sms_confirmation

        expect(flash[:alert]).to include("Incorrect SMS code")
      end
    end

    it do
      expect { sms_confirmation }.to change { user.reload.mfa_sms_enabled }.from(false).to(true)
    end
  end

  describe "#DELETE sms_removal" do
    subject(:sms_removal) { delete(:sms_removal, params: params, session: mfa_event_session_hash(mfa_event:)) }

    let(:mfa_event) { RailsBase::MfaEvent.sms_disable(user:) }
    let(:password) { "password123" }
    let(:input_password) { password }
    let(:user) { create(:user, :sms_enabled, password: password) }
    let(:datum) { RailsBase::Mfa::Sms::Send.new(user: user, expires_at: 5.minutes.from_now).create_short_lived_data }
    let(:mfa_code) { datum.data }
    let(:params) { { password: input_password, sms_code: mfa_code } }

    context "with invalid mfa event" do
      context "with invalid name" do
        let(:mfa_event) { RailsBase::MfaEvent.login_event(user:) }

        it do
          sms_removal

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          sms_removal

          expect(flash[:alert]).to include("Unauthorized MFA event")
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        it do
          sms_removal

          expect(flash[:alert]).to include("MFA event for #{mfa_event.event}")
        end

        it do
          sms_removal

          expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
        end
      end
    end

    context "with incorrect password" do
      let(:input_password) { "incorrect Password" }

      it do
        sms_removal

        expect(flash[:alert]).to include("Incorrect credentials")
      end

      it "does not change data" do
        sms_removal

        expect(user.reload.mfa_sms_enabled).to be(true)
      end
    end

    context "with incorrect sms_code" do
      let(:mfa_code) { "incorrect mfa_code" }

      it do
        sms_removal

        expect(flash[:alert]).to include("Incorrect One Time Password Code")
      end

      it "does not change data" do
        sms_removal

        expect(user.reload.mfa_sms_enabled).to be(true)
      end
    end

    it "changes mfa_sms_enabled" do
      sms_removal

      expect(user.reload.mfa_sms_enabled).to be(false)
    end

    it do
      sms_removal

      expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
    end
  end
end
