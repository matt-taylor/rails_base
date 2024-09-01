# frozen_string_literal: true

require 'twilio_helper'

RSpec.describe RailsBase::Mfa::Validate::SmsController, type: :controller do
  let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, expires_at: 5.minutes.from_now).encrypted_val }
  let(:sessions) { { mfa_randomized_token: mfa_randomized_token } }
  let(:user) { create(:user, :sms_enabled) }

  describe "#POST sms_send" do
    subject(:sms_send) { post(:sms_send, session: sessions, format: format) }

    let(:sign_user_in) { false }

    before do
      sign_in(user) if sign_user_in
      allow(TwilioHelper).to receive(:send_sms)
    end

    context "when invalid mfa token" do
      let(:mfa_randomized_token) { "Some Incorrect token Value" }

      context "with json format" do
        let(:format) { :json }

        it "removes mfa value" do
          sms_send

          expect(session[:mfa_randomized_token]).to be_nil
        end

        it "400 status" do
          sms_send

          expect(response.status).to eq(400)
        end

        it do
          sms_send

          expect(response.body).to include("Authorization token has expired")
        end
      end

      context "with html format" do
        let(:format) { :html }
        it "removes mfa value" do
          sms_send

          expect(session[:mfa_randomized_token]).to be_nil
        end

        it do
          sms_send

          expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
        end

        it do
          sms_send

          expect(flash[:alert]).to include("Authorization token has expired")
        end
      end
    end

    context "when user not authenticated" do
      let(:format) { :json }
      # this only happens with json as we know HTML is unauthenticated
      context "with json format" do
        it "401 status" do
          sms_send

          expect(response.status).to eq(401)
        end

        it do
          sms_send

          expect(response.body).to include("You need to sign in or sign up before continuing")
        end
      end
    end

    context "when sms send fails" do
      before do
        allow(TwilioHelper).to receive(:send_sms).and_raise(StandardError, "This is an error")
      end

      context "with json format" do
        let(:format) { :json }
        let(:sign_user_in) { true }

        it "400 status" do
          sms_send

          expect(response.status).to eq(400)
        end

        it do
          sms_send

          expect(response.body).to include("Unable to complete Request")
        end

        it "clears flash" do
          sms_send

          expect(flash.keys).to eq([])
        end
      end

      context "with html format" do
        let(:format) { :html }

        it do
          sms_send

          expect(response).to redirect_to(RailsBase.url_routes.mfa_evaluation_path(type: RailsBase::Mfa::SMS))
        end

        it do
          sms_send

          expect(flash[:alert]).to include("Unable to complete Request")
        end
      end
    end

    context "with json format (success)" do
      let(:format) { :json }
      let(:sign_user_in) { true }

      it "sets mfa value" do
        sms_send

        expect(session[:mfa_randomized_token]).to_not eq(mfa_randomized_token)
      end

      it "200 status" do
        sms_send

        expect(response.status).to eq(200)
      end

      it do
        sms_send

        expect(response.body).to include("SMS Code succesfully sent!")
      end
    end

    context "with html format (success)" do
      let(:format) { :html }

      it "sets mfa value" do
        sms_send

        expect(session[:mfa_randomized_token]).to_not eq(mfa_randomized_token)
      end

      it do
        sms_send

        expect(flash[:notice]).to include("SMS Code succesfully sent")
      end

      it do
        sms_send

        expect(response).to redirect_to(RailsBase.url_routes.mfa_evaluation_path(type: RailsBase::Mfa::SMS))
      end
    end
  end

  describe "#GET sms_login_input" do
    subject(:sms_login_input) { get(:sms_login_input, session: sessions) }

    context "with invalid/missing mfa token" do
      let(:mfa_randomized_token) { "Bad token" }

      it do
        sms_login_input

        expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
      end
    end

    it do
      sms_login_input

      expect(response).to render_template(:sms_login_input)
    end
  end

  describe "#POST sms_login" do
    subject(:sms_login) { get(:sms_login, params: params, session: sessions) }

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

    context "with invalid/missing mfa token" do
      let(:mfa_randomized_token) { "Bad token" }

      it do
        sms_login

        expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
      end
    end

    context "with incorrect MFA code" do
      before do
        key = mfa_params.keys.sample
        mfa_params[key] = "X"
      end

      it do
        sms_login

        expect(response).to redirect_to(RailsBase.url_routes.mfa_evaluation_path(type: RailsBase::Mfa::SMS))
      end
    end

    it "signs in user" do
      sms_login

      expect(user_signed_in?).to be(true)
    end

    it do
      sms_login

      expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
    end

    it do
      sms_login

      expect(flash[:notice]).to include("Welcome #{user.full_name}")
    end
  end
end
