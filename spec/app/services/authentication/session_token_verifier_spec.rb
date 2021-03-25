RSpec.describe RailsBase::Authentication::SessionTokenVerifier do
	subject(:call) { described_class.call(params) }

	let(:instance) { described_class.new(params) }
	let(:purpose) { RailsBase::Authentication::Constants::MSET_PURPOSE }
	let(:enc_purpose) { purpose }
	let(:expires_at) { Time.zone.now + 5.minutes }
	let(:value) { { user_id: User.first.id, expires_at: expires_at, rand: rand.to_s }.to_json }
	let(:mfa_randomized_token) { RailsBase::Encryption.encode(value: value, purpose: purpose, expires_at: expires_at)  }
	let(:params) { { mfa_randomized_token: mfa_randomized_token, purpose: purpose } }

	describe '#call' do
		context 'when mfa_randomized_token nil' do
			let(:mfa_randomized_token) { nil }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include('Authorization token not present') }
		end

		context 'when decoding fails' do
			context 'with bad token' do
				let(:mfa_randomized_token) { 'This token will not be decoded' }

				it { expect(call.failure?).to be true }
				it { expect(call.message).to include('Authorization token has expired') }
			end

			context 'with expired token' do
				let(:expires_at) { Time.zone.now - 5.minutes }

				it { expect(call.failure?).to be true }
				it { expect(call.message).to include('Authorization token has expired') }
			end
		end

		context 'when json fails' do
			let(:value) { "can't parse a string" }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include('Authorization token has failed') }
		end

		it { expect(call.success?).to be true }
		it { expect(call.user_id).to eq(User.first.id) }
		it { expect(call.expires_at).not_to be_nil }
	end
end
