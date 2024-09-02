# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::Totp::ValidateTemporaryCode do
  describe ".call" do
    subject (:call) { described_class.call(user: user, otp_code: otp_code) }

    let(:otp_time_at) { Time.now }
    let(:otp_code) { otp.at(otp_time_at) }
    let(:otp) { ROTP::TOTP.new(otp_secret) }

    context "with incorrect code" do
      let(:user) { create(:user, :totp_enabled) }
      let(:otp_code) { "123456" }

      it { expect(call.failure?).to be(true) }
      it { expect(call.message).to include("Invalid TOTP code") }
      it { expect(call.success?).to be(false) }
    end

    context "with correct code" do
      context "when otp_secret" do
        let(:user) { create(:user, :totp_enabled) }
        let(:otp_secret) { user.otp_secret }

        it { expect(call.backup_codes).to be_nil }
        it { expect(call.success?).to be(true) }
      end

      context "when temp_otp_secret" do
        let(:user) { create(:user, :temp_totp_enabled) }
        let(:otp_secret) { user.temp_otp_secret }

        it { expect(call.backup_codes).to be_a(Array) }
        it { expect(call.success?).to be(true) }
      end
    end
  end
end
