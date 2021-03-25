RSpec.describe RailsBase::Authentication::UpdatePhoneSendVerification do
	subject(:call) { described_class.call(params) }

	let(:user) { User.first  }
	let(:phone_number) { '1234567890'  }
	let(:params) { { user: user, phone_number: phone_number } }

	describe '#validate!' do
		context 'fails without phone_number' do
			let(:params) { super().except(:phone_number) }

			it { expect { call }.to raise_error(/Expected phone_number/) }
		end

		context 'fails without user' do
			let(:params) { super().except(:user) }

			it { expect { call }.to raise_error(/Expected user/) }
		end
	end

	describe '#call' do
		let(:sld) { double('ShortLivedData', death_time: Time.zone.now + 5.minutes) }
		let(:twilio_message) { double('SendLoginMfaToUser', failure?: twilio_failure, message: msg, short_lived_data: sld ) }
		let(:twilio_failure) { false }
		let(:msg) { 'false' }
		before { allow(RailsBase::Authentication::SendLoginMfaToUser).to receive(:call).and_return(twilio_message) }

		context 'when santized_phone fails' do
			let(:phone_number) { '8675309' }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include('Unexpected params passed') }
		end

		context 'when mfa send fails' do
			let(:twilio_failure) { true }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to eq(msg) }
		end

		it { expect(call.success?).to be true }
		it { expect(call.expires_at).to eq(Time.zone.now + 5.minutes) }
		it { expect(call.mfa_randomized_token).to_not be_nil }
		it { expect { call }.to change { user.reload.phone_number }.from(user.phone_number).to(phone_number) }
	end
end
