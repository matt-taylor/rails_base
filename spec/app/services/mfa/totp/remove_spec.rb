# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::Totp::Remove do
  describe ".call" do
    subject (:call) { described_class.call(**params) }

    let(:user) { create(:user, :totp_enabled, password: password) }
    let(:password) { "password1" }
    let(:password_input) { "password1" }
    let(:otp_code) { ROTP::TOTP.new(user.otp_secret).at(Time.now) }
    let(:params) { { user: user, otp_code: otp_code, password: password_input } }

    context "with incorrect password" do
      let(:password_input) { "incorrect password" }

      it { expect(call.failure?).to be(true) }
      it { expect(call.message).to include("Incorrect credentials") }
    end

    context "with incorrect otp_code" do
      let(:otp_code) { "1234567" }

      it { expect(call.failure?).to be(true) }
      it { expect(call.message).to include("Invalid TOTP code") }
    end

    context "when error reseting otp data" do
      before do
        allow(user).to receive(:reset_otp!).and_raise(StandardError)
      end

      it { expect(call.failure?).to be(true) }
      it { expect(call.message).to include("Yikes! Unknown error occured") }
    end

    it { expect(call.success?).to be(true) }
    it "resets user otp" do
      expect { call }.to change { user.reload.otp_secret }.from(user.otp_secret).to(nil)
        .and change { user.reload.mfa_otp_enabled }.from(user.mfa_otp_enabled).to(false)
        .and change { user.reload.otp_backup_codes }.from(user.otp_backup_codes).to([])

      expect(user.reload.last_mfa_otp_login).to be_nil
      expect(user.reload.temp_otp_secret).to be_nil
    end
  end
end
