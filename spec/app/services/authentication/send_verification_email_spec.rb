RSpec.describe RailsBase::Authentication::SendVerificationEmail do
	subject(:call) { described_class.call(params) }

	let(:instance) { described_class.new(params) }
	let(:user) { User.first }
	let(:reason) { RailsBase::Authentication::Constants::SVE_LOGIN_REASON  }
	let(:params) { { user: user, reason: reason } }

	describe '#validate!' do
		context 'fails without user' do
			let(:params) { super().except(:user) }

			it { expect { call }.to raise_error(/Expected user/) }
		end

		context 'fails without reason' do
			let(:params) { super().except(:reason) }

			it { expect { call }.to raise_error(/Expected reason/) }
		end

		context 'fails with incorrect reason' do
			let(:reason) { :incorrect_reason }

			it { expect { call }.to raise_error(/Expected #{reason} to be in/) }
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

		context 'when incorrect url' do
			before { allow_any_instance_of(described_class).to receive(:assign_url).and_raise(StandardError, 'Oops') }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include('Unknown error occurred') }
		end

		it do
		 expect(call.success?).to be true
		end

		it 'sets short_lived_data correctly' do
			expect(ShortLivedData).to receive(:create_data_key).with(
				hash_including(
					user: user,
					max_use: described_class::MAX_USE_COUNT,
					reason: reason,
					data_use: described_class::DATA_USE,
					ttl: RailsBase::Authentication::Constants::SVE_TTL,
					length: RailsBase::Authentication::Constants::EMAIL_LENGTH
				)
			).and_call_original

			call
		end
	end
end
