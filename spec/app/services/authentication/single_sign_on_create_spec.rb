RSpec.describe RailsBase::Authentication::SingleSignOnCreate do
  subject(:call) { described_class.call(params) }

  let(:instance) { described_class.new(params) }
  let(:user) { User.first }
  let(:token_length) { 32 }
  let(:token_type) { :alphanumeric }
  let(:uses) { nil }
  let(:reason) { 32 }
  let(:expires_at) { Time.zone.now + 5.minutes }
  let(:params) do
    {
      user: user,
      token_length: token_length,
      uses: uses,
      reason: reason,
      token_type: token_type,
      expires_at: expires_at
    }
  end

  describe '#validate!' do
    context 'when no user' do
      let(:params) { super().except(:user) }

      it { expect { call }.to raise_error(/Expected user/) }
    end

    context 'when incorrect expires_at' do
      let(:expires_at) { 'string' }

      it { expect { call }.to raise_error(/Expected expires_at/) }
    end

    context 'when no reason' do
      let(:reason) { nil }

      it { expect { call }.to raise_error(/Expected reason/) }
    end

    context 'when no token_length' do
      let(:token_length) { nil }

      it { expect { call }.to raise_error(/Expected token_length/) }
    end
  end

  describe '#call' do
    it 'returns the datum' do
      expect(call.data).to be_a(ShortLivedData)
    end

    context 'when incorrect SecureRandam value' do
      it 'returns correctly' do
        expect(call.data).to be_a(ShortLivedData)
      end
    end


    it 'returns the correct length' do
      expect(call.data.data.length).to be(token_length)
    end

    it 'returns success' do
      expect(call.success?).to be true
    end
  end
end
