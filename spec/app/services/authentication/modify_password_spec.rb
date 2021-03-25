RSpec.describe RailsBase::Authentication::ModifyPassword do
	subject(:call) { described_class.call(params) }

	let(:user) { User.first }
	let(:mfa_user) { user }
	let(:user_id) { user.id }
	let(:password) { 'password1' }
	let(:password_confirmation) { password }
	let(:flow) { :forgot_password }
	let(:data) { rand.to_s[2...32] }

	let(:params) {
		{
			password: password,
			password_confirmation: password_confirmation,
			data: data,
			user_id: user_id,
			flow: flow
		}
	}

	describe '#validate!' do
		context 'fails without flow' do
			let(:params) { super().except(:flow) }

			it { expect { call }.to raise_error(/Expected Flow to be/) }
		end

		context 'when current_user' do
			let(:params) { super().merge(current_user: user) }

			context 'does not care about user_id' do
				let(:params) { super().except(:user_id) }

				it { call }
			end

			context 'when :forgot_password' do
				let(:params) { super().except(:data) }

				it { expect { call }.to raise_error(/Expected data/) }
			end

			context 'when :user_settings' do
				let(:params) { super().except(:data) }
				let(:flow) { :user_settings }

				it { call }
			end

			context 'does not care about data' do

			end
		end

		context 'fails without password' do
			let(:params) { super().except(:password) }

			it { expect { call }.to raise_error(/Expected password to be/) }
		end

		context 'fails without password_confirmation' do
			let(:params) { super().except(:password_confirmation) }

			it { expect { call }.to raise_error(/Expected password_confirmation/) }
		end

		context 'fails without data' do
			let(:params) { super().except(:data) }

			it { expect { call }.to raise_error(/Expected data/) }
		end

		context 'fails without user_id' do
			let(:params) { super().except(:user_id) }

			it { expect { call }.to raise_error(/Expected user_id/) }
		end
	end

	describe '#call' do
		let!(:datum) do
			ShortLivedData.create_data_key(
				user: mfa_user,
				data: data,
				reason: RailsBase::Authentication::Constants::VFP_REASON
			)
		end
		context 'when invalid password' do
			context 'when confirmation does not match' do
				let(:password_confirmation) { super()*2 }

				it { expect(call.failure?).to be true }
				it { expect(call.message).to include('Passwords do not match') }
			end

			context 'when password is too short' do
				let(:password) { 'f' * (RailsBase::Authentication::Constants::MP_MIN_LENGTH-1) }

				it { expect(call.failure?).to be true }
				it { expect(call.message).to eq(RailsBase::Authentication::Constants::MP_REQ_MESSAGE) }
			end

			context 'when password does not have enough letters' do
				let(:password) do
					min = RailsBase::Authentication::Constants::MP_MIN_LENGTH
					chars = "f" * (RailsBase::Authentication::Constants::MP_MIN_ALPHA-1)
					"#{chars}#{"1" * (min - chars.length)}"
				end

				it { expect(call.failure?).to be true }
				it { expect(call.message).to include('characters [a-z,A-Z]') }
			end

			context 'when password does not have enough numbers' do
				let(:password) do
					min = RailsBase::Authentication::Constants::MP_MIN_LENGTH
					nums = "1" * (RailsBase::Authentication::Constants::MP_MIN_NUMS-1)
					"#{nums}#{"f" * (min - nums.length)}"
				end

				it { expect(call.failure?).to be true }
				it { expect(call.message).to include('numbers [0-9]') }
			end

			context 'when password contains unacceptable characters' do
				let(:password) { "#{super()};" }

				it { expect(call.failure?).to be true }
				it { expect(call.message).to include('[0-9a-zA-Z] exclusively') }
			end
		end

		context 'when user is not found' do
			let(:user_id) { 3 }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include('Unknown error. Please try again') }
		end

		context 'when datum is invalid' do
			let(:mfa_user) { User.second }

			it { expect(call.failure?).to be true }
			it { expect(call.message).to eq(RailsBase::Authentication::Constants::MV_FISHY) }
		end

		context 'when fails to update password' do
			before do
				allow(User).to receive(:find_by_id).with(user_id).and_return(user)
				allow(user).to receive(:update).with(password: password, password_confirmation: password_confirmation).and_return(false)
			end

			it { expect(call.failure?).to be true }
			it { expect(call.message).to include('Failed to update user') }
		end

		it { expect(call.success?).to be true }
	end
end
