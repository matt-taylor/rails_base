RSpec.describe RailsBase::Authentication::DestroyUser do
  subject(:call) { described_class.call(params) }

  let(:user) { User.first }
  let(:email) { user.email }
  let(:max_use) { 1 }
  let!(:datum) do
    ShortLivedData.create_data_key(
      user: user,
      max_use: max_use,
      reason: described_class::DATUM_REASON,
      ttl: described_class::DATUM_TTL,
      length: described_class::DATUM_LENGTH,
    )
  end
  let(:data) { datum.data }
  let(:params) { { data: data, current_user: user } }

  describe '#validate!' do
    context 'fails without data' do
      let(:params) { super().except(:data) }

      it { expect { call }.to raise_error(/Expected data/) }
    end

    context 'fails without current_user' do
      let(:params) { super().except(:current_user) }

      it { expect { call }.to raise_error(/Expected current_user/) }
    end
  end

  describe '#call' do
    context 'when invalid datum' do
      context 'when over used' do
        let(:max_use) { 0 }

        it { expect(call.failure?).to be true }
        it { expect(call.message).to eq('Errors with Destroy User token: too many uses. Please try again') }
      end

      context 'when invalid code' do
        let(:data) { 'this is an invalid code' }

        it { expect(call.failure?).to be true }
        it { expect(call.message).to eq('Invalid Data Code. Please retry action') }
      end
    end

    it 'soft destroys user' do
      call

      expect(user.mfa_sms_enabled).to be(false)
      expect(user.email_validated).to be(false)
      expect(user.last_mfa_sms_login).to be(nil)
      expect(user.encrypted_password).to eq('')
      expect(user.phone_number).to be(nil)
    end

    it { expect(call.success?).to be true }
  end
end
