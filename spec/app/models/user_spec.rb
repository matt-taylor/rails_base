RSpec.describe User do

  describe '#full_name' do
    subject(:full_name) { user.full_name }

    let(:user) { create(:user) }
    let(:name) { "#{user.first_name} #{user.last_name}" }
    it { is_expected.to eq(name) }
  end

  describe '#set_last_mfa_sms_login!' do
    subject(:set_last_mfa_sms_login) { user.set_last_mfa_sms_login! }

    let(:user) { create(:user) }
    # Time is frozen...but in memory presision is higher than DB precision. to_i is universal and will be the same
    it { expect { set_last_mfa_sms_login }.to change { user.reload.last_mfa_sms_login.to_i }.to(Time.zone.now.to_i) }
  end

  describe '#masked_phone' do
    subject(:masked_phone) { user.masked_phone }

    let(:user) { create(:user) }

    it { is_expected.to eq("(#{user.phone_number[0]}**) ****-**#{user.phone_number[-2..-1]}") }
    context 'when no phone' do
      before { allow(user).to receive(:phone_number).and_return(nil) }

      it { is_expected.to be_nil }
    end
  end

  describe '#readable_phone' do
    subject(:readable_phone) { user.readable_phone }

    let(:user) { create(:user) }
    it { is_expected.to eq("(#{user.phone_number[0..2]}) #{user.phone_number[3..5]}-#{user.phone_number[6..-1]}") }
    context 'when no phone' do
      before { allow(user).to receive(:phone_number).and_return(nil) }

      it { is_expected.to be_nil }
    end
  end

  # TOTP code Testing

  describe ".totp_drift_ahead" do
    it do
      expect(User.totp_drift_ahead).to eq(RailsBase.config.totp.allowed_drift)
    end
  end

  describe ".totp_drift_behind" do
    it do
      expect(User.totp_drift_behind).to eq(RailsBase.config.totp.allowed_drift)
    end
  end

  describe ".generate_otp_secret" do
    it do
      expect(User.generate_otp_secret.length).to eq(RailsBase.config.totp.secret_code_length)
    end
  end

  describe "#otp_provisioning_uri" do
    let(:user) { create(:user, :totp_enabled) }

    it do
      expect(user.otp_provisioning_uri).to include(ERB::Util.url_encode(user.email))
    end

    it do
      expect(user.otp_provisioning_uri).to include(ERB::Util.url_encode(RailsBase.app_name))
    end
  end

  describe "#generate_otp_backup_codes!" do
    let(:user) { create(:user) }

    it do
      expect(user.otp_backup_codes).to eq([])

      user.generate_otp_backup_codes!

      expect(user.otp_backup_codes.length).to eq(RailsBase.config.totp.backup_code_count)
      expect(user.otp_backup_codes).to all(be_a(String))
    end
  end

  describe "#invalidate_otp_backup_code!" do
    let(:user) { create(:user, :totp_enabled) }

    it "validates code and removes code" do
      expect(user.otp_backup_codes.length).to eq(RailsBase.config.totp.backup_code_count)

      expect(user.invalidate_otp_backup_code!(user.otp_backup_codes.sample)).to be(true)

      expect(user.otp_backup_codes.length).to eq(RailsBase.config.totp.backup_code_count - 1)
    end

    context "with incorrect code" do
      it do
        expect(user.invalidate_otp_backup_code!("Incorrect Code")).to be(false)
      end

      it do
        expect { user.invalidate_otp_backup_code!("Incorrect Code") }.to_not change { user.otp_backup_codes.length }
      end
    end
  end
end
