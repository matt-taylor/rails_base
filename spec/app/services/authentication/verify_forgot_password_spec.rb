# frozen_string_literal: true

RSpec.describe RailsBase::Authentication::VerifyForgotPassword do
	subject(:call) { described_class.call(params) }

	let(:user) { create(:user)  }
	let(:data) { datum.data  }
	let(:params) { { data: data } }
	let!(:datum) do
		ShortLivedData.create_data_key(
			user: user,
			reason: RailsBase::Authentication::Constants::VFP_REASON
		)
	end

	describe '#validate!' do
		context 'fails without data' do
			let(:params) { super().except(:data) }

			it { expect { call }.to raise_error(/Expected data/) }
		end

		context 'fails with incorrect data type' do
			let(:data) { 15 }

			it { expect { call }.to raise_error(/Expected data/) }
		end
	end

	describe '#call' do
		let(:twilio_message) { double('SendLoginMfaToUser', failure?: twilio_failure, message: msg ) }
		let(:twilio_failure) { false }
		let(:msg) { 'false' }
		before { allow(RailsBase::Mfa::Sms::Send).to receive(:call).and_return(twilio_message) }

		context 'when datum is invalid' do
			before do
				allow(ShortLivedData).to receive(:get_by_data).with(data: datum.data, reason: RailsBase::Authentication::Constants::VFP_REASON)
					.and_return(datum)

				allow(datum).to receive(:still_alive?).and_return(false)
			end

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include('Errors with email validation') }
			it { expect(call.redirect_url).to eq(RailsBase.url_routes.new_user_password_path) }
		end

		context 'when datum is incorrect' do
			let(:data) { 'not correct' }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to eq(RailsBase::Authentication::Constants::MV_FISHY) }
			it { expect(call.redirect_url).to eq(RailsBase.url_routes.authenticated_root_path) }
		end

		context 'when mfa enabled' do
			context "with totp primary" do
				let(:user) { create(:user, :totp_enabled, :sms_enabled)  }

				it { expect(call.success?).to be true }
				it { expect(call.mfa_flow).to be true }
				it { expect(call.user.id).to be user.id }
			end

			context "with sms primary" do
				let(:user) { create(:user, :sms_enabled)  }

				it { expect(call.success?).to be true }
				it { expect(call.mfa_flow).to be true }
				it { expect(call.user.id).to be user.id }
			end
		end

		it { expect(call.success?).to be true }
		it { expect(call.mfa_flow).to be false }
		it { expect(call.user.id).to be user.id }
	end
end
