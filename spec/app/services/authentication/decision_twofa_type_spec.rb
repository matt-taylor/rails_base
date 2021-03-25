RSpec.describe RailsBase::Authentication::DecisionTwofaType do
	subject(:call) { described_class.call(params) }

	let(:mfa_object) do
		double('RailsBase::SendLoginMfaToUser', short_lived_data: double('ShortLivedData', death_time: death_time), failure?: !mfa_success, success?: mfa_success, message: 'msg')
	end
	let(:death_time) { Time.zone.now }
	let(:mfa_success) { true }
	let(:user) { User.first }

	let(:params) { { user: user} }

	describe '#validate!' do
		context 'fails without user' do
			let(:params) { super().except(:user) }

			it { expect { call }.to raise_error(/Expected user/) }
		end
	end

	describe '#call' do
		before { allow(user).to receive(:email_validated).and_return(false) }

		context 'when email is validated' do
			before { allow(user).to receive(:email_validated).and_return(true) }

			context 'when mfa enabled' do
				before { allow(user).to receive(:mfa_enabled).and_return(true) }

				context 'when mfa expired' do
					before do
						allow(RailsBase::Authentication::SendLoginMfaToUser).to receive(:call).with(user: user).and_return(mfa_object)
						allow(user).to receive(:past_mfa_time_duration?).and_return(true)
					end

					context 'when mfa fails' do
						let(:mfa_success) { false }

						it { expect(call.failure?).to eq true }
						it { expect(call.message).to eq 'msg' }
					end

					it { expect(call.sign_in_user).to be false }
					it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.mfa_code_path }
					it { expect(call.set_mfa_randomized_token).to be true }
					it { expect(call.flash).to include({notice: /\w/ }) }
					it { expect(call.token_ttl).to eq death_time }
				end

				context 'when mfa within time' do
					before do
						allow(user).to receive(:past_mfa_time_duration?).and_return(false)
						allow(user).to receive(:last_mfa_login).and_return(Time.zone.now)
					end

					it { expect(call.sign_in_user).to be true }
					it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.authenticated_root_path }
					it { expect(call.set_mfa_randomized_token).to be false }
				end
			end

			context 'when mfa is not enabled' do
				before { allow(user).to receive(:mfa_enabled).and_return(false) }

				it { expect(call.sign_in_user).to be true }
				it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.authenticated_root_path }
				it { expect(call.set_mfa_randomized_token).to be false }
			end
		end

		context 'when email is not validated' do
			let(:mfa_decision) { double('SendVerificationEmail', failure?: !mfa_success, success?: mfa_success, message: 'msg') }
			before do
				allow(RailsBase::Authentication::SendVerificationEmail).to receive(:call).with(user: user, reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON).and_return(mfa_decision)
				allow(user).to receive(:past_mfa_time_duration?).and_return(false)
				allow(user).to receive(:last_mfa_login).and_return(Time.zone.now)
			end

			it { expect(call.sign_in_user).to be false }
			it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.auth_static_path }
			it { expect(call.mfa_purpose).to eq RailsBase::Authentication::Constants::SSOVE_PURPOSE }
			it { expect(call.set_mfa_randomized_token).to be true }
			it { expect(call.flash).to include({notice: /\w/ }) }
			it { expect(call.token_ttl).to be_a ActiveSupport::TimeWithZone }
		end
	end
end
