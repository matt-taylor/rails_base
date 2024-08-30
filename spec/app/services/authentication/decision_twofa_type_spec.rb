RSpec.describe RailsBase::Authentication::DecisionTwofaType do
	subject(:call) { described_class.call(params) }

	let(:mfa_object) do
		double('RailsBase::Mfa::Sms::Send', short_lived_data: double('ShortLivedData', death_time: death_time), failure?: !mfa_success, success?: mfa_success, message: 'msg')
	end
	let(:death_time) { Time.zone.now }
	let(:mfa_success) { true }
	let(:params) { { user: user} }
	let(:user) { create(:user) }

	describe '#validate!' do
		context 'fails without user' do
			let(:params) { super().except(:user) }

			it { expect { call }.to raise_error(/Expected user/) }
		end
	end

	describe '#call' do
		context 'when email is validated' do
			context 'when mfa is enabled on app' do
				context "with sms" do
					let(:user) { create(:user, :sms_enabled) }

					context 'when mfa required' do
						before do
							allow(RailsBase::Mfa::Sms::Send).to receive(:call).with(user: user).and_return(mfa_object)
							allow(RailsBase.config.mfa).to receive(:reauth_strategy).and_return(RailsBase::Mfa::Strategy::EveryRequest)
						end

						context 'when send fails' do
							let(:mfa_success) { false }

							it { expect(call.failure?).to eq true }
							it { expect(call.message).to eq 'msg' }
						end

						it { expect(call.sign_in_user).to be false }
						it { expect(call.redirect_url).to eq RailsBase.url_routes.mfa_evaluation_path }
						it { expect(call.set_mfa_randomized_token).to be true }
						it { expect(call.flash).to include({notice: /\w/ }) }
						it { expect(call.token_ttl).to eq death_time }
					end

					context 'when mfa not required' do
						before do
							allow(RailsBase.config.mfa).to receive(:reauth_strategy).and_return(RailsBase::Mfa::Strategy::SkipEveryRequest)
						end

						it { expect(call.sign_in_user).to be true }
						it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.authenticated_root_path }
						it { expect(call.set_mfa_randomized_token).to be false }
					end
				end
			end

			context 'when mfa is disabled on app' do
				before do
					allow(RailsBase.config.mfa).to receive(:enable?).and_return(false)
				end

				it do
					expect(RailsBase::Mfa::Decision).to_not receive(:call)

					call
				end

				it { expect(call.sign_in_user).to be true }
				it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.authenticated_root_path }
				it { expect(call.set_mfa_randomized_token).to be false }
				it { expect(call.flash).to include({notice: /succesfully signed in/ }) }
			end
		end

		context 'when email is not validated' do
			let(:user) { create(:user, :unvalidated_email) }
			let(:mfa_decision) { double('SendVerificationEmail', failure?: !mfa_success, success?: mfa_success, message: 'msg') }
			before do
				allow(RailsBase::Authentication::SendVerificationEmail).to receive(:call).with(user: user, reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON).and_return(mfa_decision)
				allow(user).to receive(:last_mfa_sms_login).and_return(Time.zone.now)
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
