RSpec.describe RailsBase::NameChange do
	subject(:call) { described_class.call(params) }

	let(:instance) { described_class.new(params) }
	let(:current_user) { User.first }

	let(:params) {
		{
			first_name: 'FirstName',
			last_name: 'LastName',
			current_user: current_user,
		}
	}

	describe '#validate!' do
		context 'fails without first_name' do
			let(:params) { super().except(:first_name) }

			it { expect { call }.to raise_error(/Expected first_name/) }
		end

		context 'fails without last_name' do
			let(:params) { super().except(:last_name) }

			it { expect { call }.to raise_error(/Expected last_name/) }
		end

		context 'fails without current_user' do
			let(:params) { super().except(:current_user) }

			it { expect { call }.to raise_error(/Expected current_user/) }
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

		context 'fails to update user' do
			before { allow(current_user).to receive(:update).and_return(false) }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include("Unable to update name") }
		end

		it 'sends email' do
			expect(RailsBase::EmailVerificationMailer).to receive(:event).with(user: current_user, event: /Succesfull name change/).and_call_original

			call
		end
	end
end
