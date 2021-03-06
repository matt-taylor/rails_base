RSpec.describe RailsBase::Authentication::MfaValidator do
	subject(:call) { described_class.call(params) }

	let(:user) { User.first }
	let(:current_user) { user }
	let(:mfa) { rand.to_s[2..(2+(RailsBase::Authentication::Constants::MFA_LENGTH-1))] }
	let(:session_mfa_user_id) { user.id }
	let(:mfa_params) {
		_params = {}
		RailsBase::Authentication::Constants::MFA_LENGTH.times do |index|
			var_name = "#{RailsBase::Authentication::Constants::MV_BASE_NAME}#{index}".to_sym
			_params[var_name] = mfa.split('')[index]
		end
		_params
	}

	let(:input_params) { { mfa: mfa_params } }

	let(:params) {
		{
			params: input_params,
			session_mfa_user_id: session_mfa_user_id,
			current_user: current_user
		}
	}

	describe '#validate!' do
		context 'fails without params' do
			let(:params) { super().except(:params) }

			it { expect { call }.to raise_error(/Expected the params/) }
		end

		context 'fails without session_mfa_user_id' do
			let(:params) { super().except(:session_mfa_user_id) }

			it { expect { call }.to raise_error(/session_mfa_user_id/) }
		end
	end

	describe '#call' do
		let!(:datum) do
			ShortLivedData.create_data_key(
				user: user,
				data: mfa,
				reason: reason
			)
		end
		let(:reason) { RailsBase::Authentication::Constants::MFA_REASON }

		context 'when array length is incorrect' do
			let(:mfa_params) { super().except(super().keys.last) }

			it { expect(call.failure?).to eq true }
			it { expect(call.message).to eq RailsBase::Authentication::Constants::MV_FISHY }
			it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.new_user_session_path }
			it { expect(call.level).to eq :alert }
		end

		context 'when incorrect datum(mfa)' do
			before { allow(ShortLivedData).to receive(:get_by_data).with(data: mfa, reason: reason).and_return(nil) }

			it { expect(call.failure?).to eq true }
			it { expect(call.message).to include('Incorrect MFA code') }
			it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.mfa_code_path }
			it { expect(call.level).to eq :warn }
		end

		context 'when invalid datum(mfa)' do
			before do
				allow(ShortLivedData).to receive(:get_by_data).with(data: mfa, reason: reason).and_return(datum)
				allow(datum).to receive(:still_alive?).and_return(false)
			end

			it { expect(call.failure?).to eq true }
			it { expect(call.message).to include('Errors with MFA') }
			it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.new_user_session_path }
			it { expect(call.level).to eq :warn }
		end

		context 'when datum user and mfa token user mismatch' do
			let(:session_mfa_user_id) { "#{super()}000000000000" }

			it { expect(call.failure?).to eq true }
			it { expect(call.message).to eq RailsBase::Authentication::Constants::MV_FISHY }
			it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.new_user_session_path }
			it { expect(call.level).to eq :alert }
		end

		context 'when datum user and mfa token user mismatch' do
			let(:current_user) { User.second }

			it { expect(call.failure?).to eq true }
			it { expect(call.message).to eq 'You are a teapot' }
			it { expect(call.redirect_url).to eq RailsBase::Authentication::Constants::URL_HELPER.signout_path }
			it { expect(call.level).to eq :warn }
		end

		it { expect(call.success?).to eq true }
		it { expect(call.user).to eq user }

	end
end
