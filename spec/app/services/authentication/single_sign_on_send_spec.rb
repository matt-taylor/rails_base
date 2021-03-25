require 'twilio_helper'

RSpec.describe RailsBase::Authentication::SingleSignOnSend do
  subject(:call) { described_class.call(params) }

  let(:instance) { described_class.new(params) }
  let(:user) { User.first }
  let(:token_length) { 32 }
  let(:token_type) { :alphanumeric }
  let(:uses) { nil }
  let(:reason) { 32 }
  let(:expires_at) { Time.zone.now + 5.minutes }
  let(:params) do
    {
      user: user,
      token_length: token_length,
      uses: uses,
      reason: reason,
      token_type: token_type,
      expires_at: expires_at
    }
  end

  describe '#validate!' do
    context 'when no user' do
      let(:params) { super().except(:user) }

      it { expect { call }.to raise_error(/Expected user/) }
    end
  end

  describe '#call' do
    context 'when sso_decision_type is invalid' do
      before do
        allow(user).to receive(:phone_number).and_return(nil)
        allow(user).to receive(:email_validated).and_return(false)
      end

      it 'fails' do
        expect(call.failure?).to be true
      end
    end

    context 'when sending via phone' do
      context 'when twilio fails' do
        before { allow(TwilioHelper).to receive(:send_sms).and_raise(StandardError) }

        it 'returns message' do
          expect(call.message).to eq("Failed to send sms to user. Try again.")
        end

        it 'fails interactor' do
          expect(call.failure?).to be true
        end
      end

      it 'sends to twilio' do
        expect(TwilioHelper).to receive(:send_sms).with(
          message: /Hello #{user.full_name}. This is your SSO link/,
          to: user.phone_number
        )

        call
      end

      it 'returns successful' do
        expect(call.success?).to be true
      end
    end

    context 'when sending via email' do
      before do
        allow(user).to receive(:phone_number).and_return(nil)
        allow(user).to receive(:email_validated).and_return(true)
      end

      context 'when twilio fails' do
        before { allow(RailsBase::EventMailer).to receive(:send_sso).and_raise(StandardError) }

        it 'returns message' do
          expect(call.message).to eq("Failed to send email to user. Try again.")
        end

        it 'fails interactor' do
          expect(call.failure?).to be true
        end
      end

      it 'sends email' do
        expect { call }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'returns successful' do
        expect(call.success?).to be true
      end
    end
  end
end
