# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::Decision do
  describe "#call" do
    subject(:call) { described_class.call(user: user) }
    before { allow(RailsBase.config.mfa).to receive(:reauth_strategy).and_return(reauth_strategy) }

    let(:reauth_strategy) { RailsBase::Mfa::Strategy::SkipEveryRequest }
    context "when application MFA is disabled" do
      before { allow(RailsBase.config.mfa).to receive(:enable?).and_return(false) }
      let(:user) { create(:user) }

      it { expect(call.mfa_type).to eq(RailsBase::Mfa::NONE) }
      it { expect(call.mfa_require).to eq(false) }
    end

    context "when user has no MFA enabled" do
      let(:user) { create(:user) }

      it { expect(call.mfa_type).to eq(RailsBase::Mfa::NONE) }
      it { expect(call.mfa_require).to eq(false) }
    end

    context "when totp enabled" do
      let(:user) { create(:user, :totp_enabled) }

      it { expect(call.mfa_type).to eq(RailsBase::Mfa::OTP) }
      it { expect(call.mfa_require).to eq(false) }

      context "when mfa_require required" do
        let(:reauth_strategy) { RailsBase::Mfa::Strategy::EveryRequest }

        it { expect(call.mfa_type).to eq(RailsBase::Mfa::OTP) }
        it { expect(call.mfa_require).to eq(true) }
      end
    end

    context "when sms enabled" do
      let(:user) { create(:user, :sms_enabled) }

      it { expect(call.mfa_type).to eq(RailsBase::Mfa::SMS) }
      it { expect(call.mfa_require).to eq(false) }

      context "when mfa_require required" do
        let(:reauth_strategy) { RailsBase::Mfa::Strategy::EveryRequest }

        it { expect(call.mfa_type).to eq(RailsBase::Mfa::SMS) }
        it { expect(call.mfa_require).to eq(true) }
      end
    end

    context "when sms and otp enabled" do
      let(:user) { create(:user, :sms_enabled, :totp_enabled) }

      it { expect(call.mfa_type).to eq(RailsBase::Mfa::OTP) }
      it { expect(call.mfa_require).to eq(false) }

      context "when mfa_require required" do
        let(:reauth_strategy) { RailsBase::Mfa::Strategy::EveryRequest }

        it { expect(call.mfa_type).to eq(RailsBase::Mfa::OTP) }
        it { expect(call.mfa_require).to eq(true) }
      end
    end
  end
end
