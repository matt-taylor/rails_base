RSpec.describe RailsBase::Authentication::AuthenticateUser do
	subject(:call) { described_class.call(params) }

	let(:user) { User.first }
	let(:email) { user.email }
	let(:password) { 'password1' }
	let(:params) { { email: email, password: password } }

	describe '#validate!' do
		context 'fails without email' do
			let(:params) { super().except(:email) }

			it { expect { call }.to raise_error(/Expected email/) }
		end

		context 'fails without password' do
			let(:params) { super().except(:password) }

			it { expect { call }.to raise_error(/Expected password/) }
		end
	end

	describe '#call' do
		context 'when user is not found' do
			let(:email) { 'this is not an email and will fail' }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to eq('Incorrect credentials. Please try again') }
		end

		context 'when incorrect password' do
			let(:password) { 'this is not an password and will fail' }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to eq('Incorrect credentials. Please try again') }
		end

		it { expect(call.user).to eq(user) }
		it { expect(call.success?).to be true }
	end
end
