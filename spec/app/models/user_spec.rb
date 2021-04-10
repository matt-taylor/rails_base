RSpec.describe User do
  let(:instance) { User.first }

  describe '.time_bound' do
    subject(:time_bound) { described_class.time_bound }

    it { is_expected.to eq(Time.zone.now - RailsBase.config.auth.mfa_time_duration) }
  end

  describe '#full_name' do
    subject(:full_name) { instance.full_name }

    let(:name) { "#{instance.first_name} #{instance.last_name}" }
    it { is_expected.to eq(name) }
  end

  describe '#past_mfa_time_duration?' do
    subject(:past_mfa_time_duration) { instance.past_mfa_time_duration? }

    context 'when assigned' do
      let(:time) { Time.zone.now }
      before { allow(instance).to receive(:last_mfa_login).and_return(time) }

      it { is_expected.to eq(false) }
      context 'when past time' do
        let(:time) { described_class.time_bound - 1.second }

        it { is_expected.to eq(true) }
      end
    end

    it { is_expected.to eq(true) }
  end

  describe '#set_last_mfa_login!' do
    subject(:set_last_mfa_login) { instance.set_last_mfa_login! }

    # Time is frozen...but in memory presision is higher than DB precision. to_i is universal and will be the same
    it { expect { set_last_mfa_login }.to change { instance.reload.last_mfa_login.to_i }.to(Time.zone.now.to_i) }
  end

  describe '#masked_phone' do
    subject(:masked_phone) { instance.masked_phone }

    it { is_expected.to eq("(#{instance.phone_number[0]}**) ****-**#{instance.phone_number[-2..-1]}") }
    context 'when no phone' do
      before { allow(instance).to receive(:phone_number).and_return(nil) }

      it { is_expected.to be_nil }
    end
  end
end
