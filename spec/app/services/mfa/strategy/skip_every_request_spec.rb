# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::Strategy::SkipEveryRequest do
  describe ".description" do
    subject(:call) { described_class.description }

    it { is_expected.to include("MFA is never requried") }
  end

  describe "#call" do
    subject(:call) { described_class.call(user:, mfa_type:, mfa_last_used:, force:) }

    let(:user) { create(:user) }
    let(:mfa_type) { RailsBase::Mfa::MFA_DECISIONS.sample }
    let(:mfa_last_used) { Time.now }
    let(:force) { nil }

    it { expect(call.success?).to be(true) }
    it { expect(call.request_mfa).to be(false) }

    context "when forced" do
      let(:force) { true }

      it { expect(call.success?).to be(true) }
      it { expect(call.request_mfa).to be(true) }
    end
  end
end
