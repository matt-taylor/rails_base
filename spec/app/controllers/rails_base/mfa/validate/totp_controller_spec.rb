# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::Validate::TotpController, type: :controller do
  let(:session) { mfa_event_session_hash(mfa_event:) }
  let(:user) { create(:user, :totp_enabled)}
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

  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "#GET totp_event_input" do
    subject(:totp_event_input) { get(:totp_event_input, params:, session:) }

    context "with invalid mfa event" do
      context "with invalid name" do
        let(:input_event) { "this_is_not_the_correct_event_name" }

        it do
          totp_event_input

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          totp_event_input

          expect(flash[:alert]).to include("Unauthorized MFA event")
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        it do
          totp_event_input

          expect(flash[:alert]).to include("MFA event for #{input_event}")
        end

        it do
          totp_event_input

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end
      end
    end

    it do
      totp_event_input

      expect(response).to render_template(:totp_event_input)
    end
  end

  describe "#POST totp_event" do
    subject(:totp_event) { post(:totp_event, session:, params:) }

    let(:params) { super().merge(totp_code:) }
    let(:totp_code) { ROTP::TOTP.new(user.otp_secret).at(Time.now) }


    context "with invalid mfa event" do
      context "with invalid name" do
        let(:input_event) { "this_is_no_the_correct_event_name" }

        it do
          totp_event

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          totp_event

          expect(flash[:alert]).to include("Unauthorized MFA event")
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        it do
          totp_event

          expect(flash[:alert]).to include("MFA event for #{input_event}")
        end

        it do
          totp_event

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end
      end
    end

    context "with incorrect otp code" do
      let(:totp_code) { "12345" }

      it do
        totp_event

        expect(response).to redirect_to(RailsBase.url_routes.mfa_with_event_path(mfa_event: input_event, type: RailsBase::Mfa::OTP))
      end

      it do
        totp_event

        expect(flash[:alert]).to include("Invalid TOTP code")
      end
    end

    context "when mfa event signs user in" do
      let(:sign_in_user) { true }

      it "signs in user" do
        totp_event

        expect(user_signed_in?).to be(true)
      end

      it "signs in correct user" do
        totp_event

        expect(current_user.id).to eq(user.id)
      end
    end

    context "when mfa event sets satiated" do
      let(:set_satiated_on_success) { true }

      it "satiates event and persists to session" do
        totp_event

        expect(mfa_event_from_session(event_name: input_event).satiated?).to eq(true)
      end
    end

    it "does not satiate event" do
      totp_event

      expect(mfa_event_from_session(event_name: input_event).satiated?).to eq(false)
    end

    it "does not sign in user" do
      totp_event

      expect(user_signed_in?).to be(false)
    end

    it do
      totp_event

      expect(response).to redirect_to(redirect)
    end

    it do
      totp_event

      expect(flash[:notice]).to include(flash_notice)
    end
  end
end
