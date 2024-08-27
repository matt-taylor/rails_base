RSpec.describe User do
  let(:instance) { User.first }

  describe '#full_name' do
    subject(:full_name) { instance.full_name }

    let(:name) { "#{instance.first_name} #{instance.last_name}" }
    it { is_expected.to eq(name) }
  end

  describe '#set_last_mfa_sms_login!' do
    subject(:set_last_mfa_sms_login) { instance.set_last_mfa_sms_login! }

    # Time is frozen...but in memory presision is higher than DB precision. to_i is universal and will be the same
    it { expect { set_last_mfa_sms_login }.to change { instance.reload.last_mfa_sms_login.to_i }.to(Time.zone.now.to_i) }
  end

  describe '#masked_phone' do
    subject(:masked_phone) { instance.masked_phone }

    it { is_expected.to eq("(#{instance.phone_number[0]}**) ****-**#{instance.phone_number[-2..-1]}") }
    context 'when no phone' do
      before { allow(instance).to receive(:phone_number).and_return(nil) }

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
    it do
      expect(instance.otp_provisioning_uri).to include(ERB::Util.url_encode(instance.email))
    end

    it do
      expect(instance.otp_provisioning_uri).to include(ERB::Util.url_encode(RailsBase.app_name))
    end
  end

  describe "#generate_otp_backup_codes!" do
    let(:empty_user) { User.second }

    it do
      expect(empty_user.otp_backup_codes).to eq([])

      empty_user.generate_otp_backup_codes!

      expect(empty_user.otp_backup_codes.length).to eq(RailsBase.config.totp.backup_code_count)
      expect(empty_user.otp_backup_codes).to all(be_a(String))
    end
  end

  describe "#invalidate_otp_backup_code!" do
    it "validates code and removes code" do
      expect(instance.otp_backup_codes.length).to eq(RailsBase.config.totp.backup_code_count)

      expect(instance.invalidate_otp_backup_code!(instance.otp_backup_codes.sample)).to be(true)

      expect(instance.otp_backup_codes.length).to eq(RailsBase.config.totp.backup_code_count - 1)
    end

    context "with incorrect code" do
      it do
        expect(instance.invalidate_otp_backup_code!("Incorrect Code")).to be(false)
      end

      it do
        expect { instance.invalidate_otp_backup_code!("Incorrect Code") }.to_not change { instance.otp_backup_codes.length }
      end
    end
  end
end
