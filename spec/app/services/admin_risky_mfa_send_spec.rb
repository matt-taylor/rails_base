RSpec.describe RailsBase::AdminRiskyMfaSend do
  subject(:call) { described_class.call(params) }

  let(:instance) { described_class.new(params) }
  let(:user) { User.first }
  let(:expires_at) { Time.zone.now + 5.minutes }
  let(:reason) { "#{(rand * 10**10).to_i}" }
  let(:params) { { user: user, reason: reason } }

  describe '#validate!' do
    context 'fails without user' do
      let(:params) { super().except(:user) }

      it { expect { call }.to raise_error(/Expected user/) }
    end

    context 'fails without expires_at correct type' do
      let(:reason) { nil }

      it { expect { call }.to raise_error(/Expected reason/) }
    end
  end

  describe '#call' do
    context 'when velocity limit reached' do
      before do
        instance.vl_write!(Array.new(instance.velocity_max, Time.zone.now))
      end

      it { expect(call.failure?).to be true }
      it { expect(call.message).to include('Velocity limit reached for') }
    end

    context 'when twilio call fails' do
      before { allow(TwilioHelper).to receive(:send_sms).and_raise(StandardError, 'Oops') }

      it { expect(call.failure?).to be true }
      it { expect(call.message).to include('Failed to send sms') }
    end

    context 'when it succeeds' do
      before { allow(TwilioHelper).to receive(:send_sms).with(message: anything, to: user.phone_number).and_return(SecureRandom.uuid) }

      it { expect(call.success?).to be true }
      it { expect(call.short_lived_data).to be_a ShortLivedData }
    end
  end
end
