RSpec.describe ShortLivedData do
  let(:user) { User.first }

  let(:params) do
    {
      user: user,
      max_use: max_use,
      data: data,
      data_use: data_use,
      expires_at: expires_at,
      ttl: ttl,
      reason: reason,
      length: length,
      extra: extra
    }.compact
  end
  let(:max_use) { nil }
  let(:data) { nil }
  let(:data_use) { nil }
  let(:expires_at) { nil }
  let(:ttl) { nil }
  let(:reason) { nil }
  let(:length) { nil }
  let(:extra) { nil }

  describe '.create_data_key' do
    subject(:create_data_key) { described_class.create_data_key(params) }

    context 'when max_use defined' do
      let(:max_use) { 5 }

      it { expect(create_data_key.exclusive_use_count_max).to eq(max_use) }
    end

    context 'when data defined' do
      let(:data) { 'DataToSave' }

      it { expect(create_data_key.data).to eq(data) }
      it { expect(described_class).not_to receive(:generate_secure_datum) }
    end

    context 'when data_use defined' do
      context 'with numeric' do
        let(:data_use) { :numeric }
        it do
          expect(described_class).to receive(:rand).and_call_original
          create_data_key
        end
      end

      context 'with alphanumeric' do
        let(:data_use) { :alphanumeric }
        it do
          expect(SecureRandom).to receive(data_use).and_call_original
          create_data_key
        end
      end

      context 'with hex' do
        let(:data_use) { :hex }
        it do
          expect(SecureRandom).to receive(data_use).and_call_original
          create_data_key
        end
      end

      context 'with uuid' do
        let(:data_use) { :uuid }
        it do
          expect(SecureRandom).to receive(data_use).and_call_original
          create_data_key
        end
      end

      context 'when invalid' do
        let(:data_use) { :something_else }
        it { expect { create_data_key }.to raise_error(ArgumentError, /Unexpected data_use/) }
      end
    end

    context 'when data_use defined' do

    end

    context 'when data and reason exist' do
    end

    it 'has default ttl' do
    end
  end
end
