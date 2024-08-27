RSpec.describe RailsBase::Authentication::SsoVerifyEmail do
	subject(:call) { described_class.call(params) }

	let(:user) { User.first  }
	let(:verification) { datum.data  }
	let(:params) { { verification: verification } }
	let!(:datum) do
		ShortLivedData.create_data_key(
			user: user,
			reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON
		)
	end

	describe '#validate!' do
		context 'fails without verification' do
			let(:params) { super().except(:verification) }

			it { expect { call }.to raise_error(/verification is expected/) }
		end
	end

	describe '#call' do
		let(:mfa_params) do
			{
				expires_at: Time.zone.now + RailsBase::Authentication::Constants::SVE_TTL,
				user: user,
				purpose: RailsBase::Authentication::Constants::SSOVE_PURPOSE
			}
		end
		context 'when datum is invalid' do
			before do
				allow(ShortLivedData).to receive(:get_by_data).with(data: datum.data, reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON)
					.and_return(datum)

				allow(datum).to receive(:still_alive?).and_return(false)
			end

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include('Errors with Email Verification') }
			it { expect(call.redirect_url).to eq(RailsBase::Authentication::Constants::URL_HELPER.new_user_session_path) }
		end


		it { expect(call.success?).to be true }
		it { expect { call }.to change { user.reload.email_validated }.from(false).to(true) }
		it { expect(call.encrypted_val).not_to be_nil }
		it do
			expect(RailsBase::Mfa::EncryptToken).to receive(:call).with(mfa_params).and_call_original

			call
		end
	end
end
