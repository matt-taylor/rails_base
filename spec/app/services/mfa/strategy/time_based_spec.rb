# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::Strategy::TimeBased do
  describe ".description" do
    subject(:call) { described_class.description }

    it { is_expected.to include("MFA is required every #{RailsBase.config.mfa.reauth_duration}") }
  end

  describe "#call" do
    subject(:call) { described_class.call(user:, mfa_type:, mfa_last_used:, force:) }

    let(:user) { create(:user) }
    let(:mfa_type) { RailsBase::Mfa::MFA_DECISIONS.sample }
    let(:mfa_last_used) { 10.minutes.ago  }
    let(:force) { nil }

    context "when mfa_last_used is nil" do
      let(:mfa_last_used) { nil }

      it { expect(call.success?).to be(true) }
      it { expect(call.request_mfa).to be(true) }
    end

    context "when outside of time based decision" do
      let(:mfa_last_used) { (RailsBase.config.mfa.reauth_duration + 1.minutes).ago  }

      it { expect(call.success?).to be(true) }
      it { expect(call.request_mfa).to be(true) }
    end

    context "when within of time based decision" do
      let(:mfa_last_used) { (RailsBase.config.mfa.reauth_duration - 1.minutes).ago  }

      it { expect(call.success?).to be(true) }
      it { expect(call.request_mfa).to be(false) }
    end

    context "when forced" do
      let(:force) { true }

      it { expect(call.success?).to be(true) }
      it { expect(call.request_mfa).to be(true) }
    end
  end
end
