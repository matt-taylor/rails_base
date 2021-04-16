RSpec.describe RailsBase::EmailChange do
  subject(:call) { described_class.call(params) }

  let(:instance) { described_class.new(params) }
  let(:email) { 'somefake_new_email_addy@hotstuff.com' }
  let!(:og_email) { user.email }
  let(:user) { User.first }
  let(:params) {
    {
      email: email,
      user: user,
    }
  }

  describe '#validate!' do
    context 'fails without email' do
      let(:params) { super().except(:email) }

      it { expect { call }.to raise_error(/Expected email/) }
    end

    context 'fails without last_name' do
      let(:params) { super().except(:user) }

      it { expect { call }.to raise_error(/Expected user/) }
    end
  end

  describe '#call' do
    context 'when email already taken' do
      let(:email) { User.second.email }

      it { expect(call.failure?).to be true }
      it { expect(call.message).to include("Unable to update email address. Likely that this email is already taken") }
    end

    it { expect(call.success?).to be true }
    it { expect(call.original_email).to eq og_email }
    it { expect(call.new_email).to eq email }

    it { expect { call }.to change { user.reload.email }.from(og_email).to(email) }
  end
end
