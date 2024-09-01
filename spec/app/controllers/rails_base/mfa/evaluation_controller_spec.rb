# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::EvaluationController, type: :controller do
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
  let(:user) { create(:user) }


  describe "# GET mfa_with_event" do
    subject(:mfa_with_event) { get(:mfa_with_event, params:, session:) }

    context "with invalid mfa event" do
      context "with invalid name" do
        let(:input_event) { "this_is_not_the_correct_event_name" }

        it do
          mfa_with_event

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          mfa_with_event

          expect(flash[:alert]).to include("Unauthorized MFA event")
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        it do
          mfa_with_event

          expect(flash[:alert]).to include("MFA event for #{input_event}")
        end

        it do
          mfa_with_event

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end
      end
    end

    context "with no param" do
      context "when totp only" do
        let(:user) { create(:user, :totp_enabled) }

        it do
          mfa_with_event

          expect(response).to render_template(described_class::OTP_TEMPLATE)
        end
      end

      context "when sms only" do
        let(:user) { create(:user, :sms_enabled) }

        it do
          mfa_with_event

          expect(response).to render_template(described_class::SMS_TEMPLATE)
        end
      end

      context "when totp and sms" do
        let(:user) { create(:user, :totp_enabled, :sms_enabled) }

        it do
          mfa_with_event

          expect(response).to render_template(described_class::OTP_TEMPLATE)
        end
      end
    end

    context "with allowed param" do
      let(:user) { create(:user, :totp_enabled, :sms_enabled) }

      context "with sms" do
        let(:params) { super().merge(type: RailsBase::Mfa::SMS.to_s) }

        it do
          mfa_with_event

          expect(response).to render_template(described_class::SMS_TEMPLATE)
        end
      end

      context "with totp" do
        let(:params) { super().merge(type: RailsBase::Mfa::OTP.to_s) }

        it do
          mfa_with_event

          expect(response).to render_template(described_class::OTP_TEMPLATE)
        end
      end
    end

    context "with disallowed param" do
      context "with sms" do
        let(:user) { create(:user, :totp_enabled) }
        let(:params) { super().merge(type: RailsBase::Mfa::SMS.to_s) }

        it do
          mfa_with_event

          expect(response).to render_template(described_class::OTP_TEMPLATE)
        end

        it "sets flash" do
          mfa_with_event

          expect(flash[:alert]).to include("Unknown MFA type #{RailsBase::Mfa::SMS}")
        end
      end

      context "with totp" do
        let(:user) { create(:user, :sms_enabled) }
        let(:params) { super().merge(type: RailsBase::Mfa::OTP.to_s) }

        it do
          mfa_with_event

          expect(response).to render_template(described_class::SMS_TEMPLATE)
        end

        it "sets flash" do
          mfa_with_event

          expect(flash[:alert]).to include("Unknown MFA type #{RailsBase::Mfa::OTP}")
        end
      end
    end
  end
end
