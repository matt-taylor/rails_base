RSpec.describe RailsBase::Authentication::SendForgotPassword do
	subject(:call) { described_class.call(params) }

	let(:user) { User.first }
	let(:email) { user.email }
	let(:params) { { email: email } }

	describe '#validate!' do
		context 'fails without email' do
			let(:params) { super().except(:email) }

			it { expect { call }.to raise_error(/Expected email/) }
		end
	end

	describe '#call' do
		context 'when email not found' do
			let(:email) { 'not an email in db' }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include('Failed to send forget password') }
		end

		context 'when email sending fails' do
			let(:email_send) { double('SendVerificationEmail', failure?: true, message: email_send_message) }
			let(:email_send_message) { 'message' }
			it do
				expect(RailsBase::Authentication::SendVerificationEmail).to receive(:call).with(user: user, reason: RailsBase::Authentication::Constants::VFP_REASON)
					.and_return(email_send)

				expect(call.failure?).to be true
			end

			it do
				expect(RailsBase::Authentication::SendVerificationEmail).to receive(:call).with(user: user, reason: RailsBase::Authentication::Constants::VFP_REASON)
					.and_return(email_send)

				expect(call.message).to eq(email_send_message)
			end
		end

		it { expect(call.message).to eq('You should receive an email shortly.') }
		it { expect(call.success?).to be true }
	end
end
