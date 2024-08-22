# frozen_string_literal: true

RSpec.describe RailsBase::Authentication::Totp::ValidateCode do
  shared_examples "otp_secret present" do
    context "when otp_code is incorrect" do
      let(:otp_code) { "1234567890" }

      it { expect(call.failure?).to be(true) }
      it { expect(call.message).to include("Invalid TOTP code") }
      it { expect(call.success?).to be(false) }
    end

    context "when otp_code is valid" do
      it { expect(call.success?).to be(true) }
    end

    context "when otp_code consumed" do
      before { described_class.call(user: user, otp_code: otp_code, otp_secret: otp_secret) }

      context "when consumed within same interval" do
        it { expect(call.failure?).to be(true) }
        it { expect(call.message).to include("Invalid TOTP code") }
        it { expect(call.success?).to be(false) }
        it "populates consumed_timestep" do
          expect(user.consumed_timestep).to_not be_nil
        end
      end

      context "when consumed in next interval" do
        before { Timecop.travel(Time.now + otp.interval - 1) }

        it { expect(call.failure?).to be(true) }

        it do
          expect { call }.to_not change { user.consumed_timestep }
        end
      end
    end

    context "when otp_code is within drift time" do
      before do
        # establish OTP code for current interval -- This gets memoized
        otp_code

        # Travel into future to max drift time
        Timecop.travel(Time.now + User.totp_drift_ahead)
      end

      it { expect(call.success?).to be(true) }
    end

    context "when otp_code is outside drift time" do
      # Drift time refers to time allowed past the end of a time interval
      # Because the current time may be at the start, we may need at most 2 drift aheads to get to
      # out of range drift time
      let(:otp_time_at) { Time.now + User.totp_drift_ahead * 2 }

      it { expect(call.success?).to be(false) }
      it { expect(call.message).to include("Invalid TOTP code") }
    end
  end

  describe ".call" do
    subject (:call) { described_class.call(user: user, otp_code: otp_code, otp_secret: otp_secret) }

    let(:otp_secret) { nil }
    let(:otp_time_at) { Time.now }
    let(:otp_code) { otp.at(otp_time_at) }
    let(:otp) { ROTP::TOTP.new(otp_secret || user.otp_secret) }

    context "with otp_secret provided" do
      let(:user) { create(:user, :temp_totp_enabled) }
      let(:otp_secret) { user.temp_otp_secret }

      include_examples "otp_secret present"
    end

    context "with otp_secret on user" do
      let(:user) { create(:user, :totp_enabled) }

      include_examples "otp_secret present"
    end

    context "with no otp_secret available" do
      let(:user) { create(:user) }
      let(:otp_code) { "1234" }

      it do
        expect { call }.to raise_error(StandardError, /Expected `otp_secret` passed in or `otp_secret` present on User/)
      end
    end
  end
end
