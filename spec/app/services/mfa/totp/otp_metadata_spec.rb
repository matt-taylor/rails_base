# frozen_string_literal: true

RSpec.describe RailsBase::Mfa::Totp::OtpMetadata do
  describe ".call" do
    subject (:call) { described_class.call(user: user) }

    context "when otp_token is not provisioned" do
      let(:user) { create(:user) }

      it "generates otp metadata" do
        expect(call.metadata[:secret]).to eq(user.reload.temp_otp_secret)
        expect(call.metadata[:uri]).to eq(user.otp_provisioning_uri({ otp_secret: call.metadata[:secret]} ))
        expect(call.metadata[:qr_code]).to_not be_nil
      end

      context "when temp token was provisioned" do
        let(:user) { create(:user, :temp_totp_enabled) }

        it "generates otp metadata" do
          expect(call.metadata[:secret]).to eq(user.reload.temp_otp_secret)
          expect(call.metadata[:uri]).to eq(user.otp_provisioning_uri({ otp_secret: call.metadata[:secret]} ))
          expect(call.metadata[:qr_code]).to_not be_nil
        end

        it "changes temp token" do
          expect { call }.to change { user.temp_otp_secret }
        end
      end
    end

    context "when otp_token is provisioned" do
      let(:user) { create(:user, :totp_enabled) }

      it "generates otp metadata from otp_token" do
        expect(call.metadata[:secret]).to eq(user.otp_secret)
        expect(call.metadata[:uri]).to eq(user.otp_provisioning_uri)
        expect(call.metadata[:qr_code]).to_not be_nil
      end

      it "does not change temp token" do
        expect { call }.to_not change { user.temp_otp_secret }
      end
    end

    context "when otp_token provisioning fails" do
      let(:user) { create(:user) }
      before do
        allow(user).to receive(:otp_metadata).and_raise(StandardError, "I have failed you")
      end

      it do
        expect(call.message).to include("Failed to retrieve Metadata for Code")
        expect(call.failure?).to be(true)
        expect(call.success?).to be(false)
      end
    end
  end
end
