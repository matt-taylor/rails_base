# frozen_string_literal: true

require 'twilio_helper'

RSpec.describe RailsBase::Mfa::Validate::SmsController, type: :controller do
  let(:user) { create(:user, :sms_enabled) }
  let(:session) { mfa_event_session_hash(mfa_event:) }
  let(:mfa_event) do
    RailsBase::MfaEvent.new(
      death_time: 1.minute.from_now,
      event:,
      flash_notice:,
      invalid_redirect:,
      redirect:,
      set_satiated_on_success:,
      sign_in_user:,
      user:,
    )
  end
  let(:params) { { mfa_event: input_event } }
  let(:event) { Faker::Lorem.word }
  let(:input_event) { event }
  let(:redirect) { RailsBase.url_routes.user_settings_path }
  let(:invalid_redirect) { RailsBase.url_routes.unauthenticated_root_path }
  let(:sign_in_user) { false }
  let(:flash_notice) { "this is a flash message on success" }
  let(:set_satiated_on_success) { false }

  describe "#POST sms_event_send" do
    subject(:sms_event_send) { post(:sms_event_send, params:, session:, format:) }

    let(:sign_user_in) { false }

    before do
      sign_in(user) if sign_user_in
      allow(TwilioHelper).to receive(:send_sms)
    end

    context "with invalid mfa event" do
      context "with invalid name" do
        let(:input_event) { "this_is_not_the_correct_event_name" }

        context "with json" do
          let(:format) { :json }

          it "400 status" do
            sms_event_send

            expect(response.status).to eq(400)
          end

          it do
            sms_event_send

            expect(response.body).to include("Unauthorized MFA event")
          end
        end

        context "with html" do
          let(:format) { :html }

          it do
            sms_event_send

            expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
          end

          it do
            sms_event_send

            expect(flash[:alert]).to include("Unauthorized MFA event")
          end
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        context "with json" do
          let(:format) { :json }

          it "400 status" do
            sms_event_send

            expect(response.status).to eq(400)
          end

          it do
            sms_event_send

            expect(response.body).to include("MFA event for #{input_event}")
          end
        end

        context "with html" do
          let(:format) { :html }

          it do
            sms_event_send

            expect(response).to redirect_to(invalid_redirect)
          end

          it do
            sms_event_send

            expect(flash[:alert]).to include("MFA event for #{input_event}")
          end
        end
      end
    end

    context "when user not authenticated" do
      let(:format) { :json }
      # JSON requests MUST only come from authenticated users
      # HTML requests may* come from unauthed or authenticated users (primarily unauthed)
      context "with json format" do
        it "401 status" do
          sms_event_send

          expect(response.status).to eq(401)
        end

        it do
          sms_event_send

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
          sms_event_send

          expect(response.status).to eq(400)
        end

        it do
          sms_event_send

          expect(response.body).to include("Unable to complete Request")
        end

        it "clears flash" do
          sms_event_send

          expect(flash.keys).to eq([])
        end
      end

      context "with html format" do
        let(:format) { :html }

        it do
          sms_event_send

          expect(response).to redirect_to(RailsBase.url_routes.mfa_with_event_path(mfa_event: input_event, type: RailsBase::Mfa::SMS))
        end

        it do
          sms_event_send

          expect(flash[:alert]).to include("Unable to complete Request")
        end
      end
    end

    context "with json format (success)" do
      let(:format) { :json }
      let(:sign_user_in) { true }

      it "200 status" do
        sms_event_send

        expect(response.status).to eq(200)
      end

      it do
        sms_event_send

        expect(response.body).to include("SMS Code succesfully sent. Please check messages")
      end
    end

    context "with html format (success)" do
      let(:format) { :html }

      it do
        sms_event_send

        expect(flash[:notice]).to include("SMS Code succesfully sent")
      end

      it do
        sms_event_send

        expect(response).to redirect_to(RailsBase.url_routes.mfa_with_event_path(mfa_event: input_event, type: RailsBase::Mfa::SMS))
      end
    end
  end

  describe "#GET sms_event_input" do
    subject(:sms_event_input) { get(:sms_event_input, session:, params:) }

    context "with invalid mfa event" do
      context "with invalid name" do
        let(:input_event) { "this_is_not_the_correct_event_name" }

        it do
          sms_event_input

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          sms_event_input

          expect(flash[:alert]).to include("Unauthorized MFA event")
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        it do
          sms_event_input

          expect(response).to redirect_to(invalid_redirect)
        end

        it do
          sms_event_input

          expect(flash[:alert]).to include("MFA event for #{input_event}")
        end
      end
    end

    it do
      sms_event_input

      expect(response).to render_template(:sms_event_input)
    end
  end

  describe "#POST sms_event" do
    subject(:sms_event) { post(:sms_event, params:, session:) }

    let(:datum) { RailsBase::Mfa::Sms::Send.new(user:, expires_at: 5.minutes.from_now).create_short_lived_data }
    let(:mfa_code) { datum.data }
    let(:mfa_params) do
      _params = {}
      RailsBase::Authentication::Constants::MFA_LENGTH.times do |index|
        var_name = "#{RailsBase::Authentication::Constants::MV_BASE_NAME}#{index}".to_sym
        _params[var_name] = mfa_code.split('')[index]
      end
      _params
    end
    let(:params) { super().merge(mfa: mfa_params) }

    context "with invalid mfa event" do
      context "with invalid name" do
        let(:input_event) { "this_is_not_the_correct_event_name" }

        it do
          sms_event

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          sms_event

          expect(flash[:alert]).to include("Unauthorized MFA event")
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        it do
          sms_event

          expect(response).to redirect_to(invalid_redirect)
        end

        it do
          sms_event

          expect(flash[:alert]).to include("MFA event for #{input_event}")
        end
      end
    end

    context "with incorrect MFA code" do
      before do
        key = mfa_params.keys.sample
        mfa_params[key] = "X"
      end

      it do
        sms_event

        expect(response).to redirect_to(RailsBase.url_routes.mfa_with_event_path(mfa_event: input_event, type: RailsBase::Mfa::SMS))
      end
    end

    context "when mfa event signs user in" do
      let(:sign_in_user) { true }

      it "signs in user" do
        sms_event

        expect(user_signed_in?).to be(true)
      end

      it "signs in correct user" do
        sms_event

        expect(current_user.id).to eq(user.id)
      end
    end

    context "when mfa event sets satiated" do
      let(:set_satiated_on_success) { true }

      it "satiates event and persists to session" do
        sms_event

        expect(mfa_event_from_session(event_name: input_event).satiated?).to eq(true)
      end
    end

    it "does not satiate event" do
      sms_event

      expect(mfa_event_from_session(event_name: input_event).satiated?).to eq(false)
    end

    it "does not sign in user" do
      sms_event

      expect(user_signed_in?).to be(false)
    end

    it do
      sms_event

      expect(response).to redirect_to(redirect)
    end

    it do
      sms_event

      expect(flash[:notice]).to include(flash_notice)
    end
  end
end
