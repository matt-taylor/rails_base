RSpec.describe RailsBase::Mfa::EncryptToken do
	subject(:call) { described_class.call(params) }

	let(:user) { User.first }
	let(:expires_at) { Time.zone.now + 33.minutes }
	let(:params) { { user: user, expires_at: expires_at } }
	let(:purpose) { RailsBase::Authentication::Constants::MSET_PURPOSE }

	describe '#validate!' do
		context 'fails without user' do
			let(:params) { super().except(:user) }

			it { expect { call }.to raise_error(/Expected user/) }
		end

		context 'fails without expires_at' do
			let(:params) { super().except(:expires_at) }

			it { expect { call }.to raise_error(/Expected expires_at/) }
		end
	end

	describe '#call' do
		let!(:rand_string) { rand.to_s }
		let(:value_params) { { user_id: user.id, rand: rand_string, expires_at: expires_at} }
		let(:encrypt_params) { { value: value_params.to_json, purpose: purpose, expires_at: expires_at } }
		before { allow_any_instance_of(Object).to receive(:rand).and_return(rand_string) }

		it 'calls Encryption class' do
			expect(RailsBase::Encryption).to receive(:encode).with(encrypt_params)

			call
		end

		context 'when custom purpose added' do
			let(:purpose) { 'some random purpose' }
			let(:params) { super().merge(purpose: purpose) }
			it 'calls Encryption class' do
				expect(RailsBase::Encryption).to receive(:encode).with(encrypt_params)

				call
			end
		end
	end
end
