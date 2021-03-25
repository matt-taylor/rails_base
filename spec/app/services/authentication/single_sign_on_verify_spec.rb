require 'twilio_helper'

RSpec.describe RailsBase::Authentication::SingleSignOnVerify do
  subject(:call) { described_class.call(service_params) }

  let(:instance) { described_class.new(params) }
  let(:service_params) { { data: data, reason: data_reason, bypass: bypass }.compact }
  let(:params) do
    {
      user: user,
      token_length: token_length,
      uses: uses,
      expires_at: expires_at,
      reason: reason,
      token_type: :alphanumeric,
      url_redirect: url_redirect,
    }.compact
  end
  let(:user) { User.first }
  let(:token_length) { 32 }
  let(:token_type) {  }
  let(:uses) { nil }
  let(:expires_at) { Time.zone.now + 5.minutes }
  let(:reason) { 'reason' }
  let(:data_reason) { reason }
  let(:bypass) { nil }
  let(:data) { datum.data.data }
  let(:url_redirect) { nil }

  let(:datum) { RailsBase::Authentication::SingleSignOnCreate.call(params) }

  describe '#validate!' do
    context 'when no data' do
      let(:data) { nil }

      it { expect { call }.to raise_error(/Expected data/) }
    end

    context 'when no reason' do
      let(:data_reason) { nil }

      it { expect { call }.to raise_error(/Expected reason/) }
    end
  end

  describe '#call' do
    context 'when bypass' do
      let(:bypass) { true }

      it 'sets data' do
        expect(call.data).to be_a(Hash)
      end

      it 'does not set sign_in' do
        expect(call.sign_in).to be_nil
      end

      it 'returns success' do
        expect(call.success?).to be true
      end
    end

    context 'when data point is not valid' do
      let(:uses) { 0 }
      it 'sets data' do
        expect(call.data).to be_a(Hash)
      end

      it 'does not set user' do
        expect(call.user).to be_nil
      end

      it 'does not set sign_in' do
        expect(call.sign_in).to be(false)
      end

      it 'returns failure' do
        expect(call.failure?).to be true
      end

      it 'returns failure messaage' do
        expect(call.message).to match(/Authorization token error/)
      end
    end

    context 'when url_redirect added' do
      let(:url_redirect) { 'this/is/a/redierct/path' }

      it 'sets url_redirect' do
        expect(call.url_redirect).to eq url_redirect
      end
    end

    it 'sets data' do
      expect(call.data).to be_a(Hash)
    end

    it 'sets user' do
      expect(call.user).to eq user
    end

    it 'sets sign_in' do
      expect(call.sign_in).to be(true)
    end

    it 'returns successful' do
      expect(call.success?).to be true
    end
  end
end
