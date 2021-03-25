require 'twilio_helper'

RSpec.describe RailsBase::MfaAuthController, type: :controller do
  let(:user) { User.first }
  let(:sessions) { { mfa_randomized_token: mfa_randomized_token } }
  let(:mfa_randomized_token) { RailsBase::Authentication::MfaSetEncryptToken.call(user: user, expires_at: expires_at).encrypted_val }
  let(:expires_at) { Time.zone.now + 5.minutes }
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  shared_examples 'bad token' do
    it 'redirects to session login' do
      subject

      expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
    end

    it 'sets flash' do
      subject

      expect(flash[:alert]).to include(message)
    end
  end

  shared_examples 'when invalid token' do
    context 'when missing token' do
      let(:sessions) { {} }
      let(:message) { 'Authorization token not present' }

      include_examples 'bad token'
    end

    context 'when token invalid' do
      let(:sessions) { {} }
      let(:message) { 'Authorization token not present' }

      include_examples 'bad token'
    end

    context 'when token is expired' do
      before { Timecop.travel(expires_at + 1.minute) }
      let(:message) { 'Authorization token has expired' }

      include_examples 'bad token'
    end
  end

  describe 'GET #mfa_code' do
  	subject(:mfa_code) { get(:mfa_code, session: sessions) }

  	include_examples 'when invalid token'

    it 'renders template' do
      mfa_code

      expect(response).to render_template(:mfa_code)
    end

    it 'assigns masked_phone' do
      mfa_code

      expect(assigns(:masked_phone)).to eq(user.masked_phone)
    end
  end

  describe 'POST #mfa_code_verify' do
    subject(:mfa_code_verify) { get(:mfa_code_verify, params: params, session: sessions) }

    let!(:datum) { RailsBase::Authentication::SendLoginMfaToUser.new(user: user, expires_at: expires_at).create_short_lived_data }
    let(:mfa_code) { datum.data }
    let(:mfa_params) do
      _params = {}
      RailsBase::Authentication::Constants::MFA_LENGTH.times do |index|
        var_name = "#{RailsBase::Authentication::Constants::MV_BASE_NAME}#{index}".to_sym
        _params[var_name] = mfa_code.split('')[index]
      end
      _params
    end
    let(:params) { { mfa: mfa_params } }

    it 'redirects to base' do
      mfa_code_verify

      expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
    end

    it 'sets flash message' do
      mfa_code_verify

      expect(flash[:notice]).to include("Welcome #{user.full_name}")
    end

    it 'signs in user' do
      mfa_code_verify

      expect(session["warden.user.user.key"][0]).to eq([user.id])
    end

    # Time is frozen...but in memory presision is higher than DB precision. to_i is universal and will be the same
    it { expect { mfa_code_verify }.to change { user.reload.last_mfa_login.to_i }.to(Time.zone.now.to_i) }

    context 'when incorrect mfa code' do
      let(:mfa_code) { 's' * RailsBase::Authentication::Constants::MFA_LENGTH  }

      it 'redirects correctly' do
        mfa_code_verify

        expect(response).to redirect_to(RailsBase.url_routes.mfa_code_path)
      end

      it 'sets flash message' do
        mfa_code_verify

        expect(request.session["flash"]["flashes"]["alert"]).to include('Incorrect MFA code.')
      end
    end

    include_examples 'when invalid token'
  end

  describe 'POST #resend_mfa' do
    subject(:resend_mfa) { get(:resend_mfa, session: sessions) }
    before { allow(TwilioHelper).to receive(:send_sms) }

    it 'sends mfa to user' do
      expect(TwilioHelper).to receive(:send_sms).with(message: anything, to: user.phone_number).and_return(SecureRandom.uuid)

      resend_mfa
    end

    it 'correctly redirects' do
      resend_mfa

      expect(response).to redirect_to(RailsBase.url_routes.mfa_code_path)
    end

    it 'sets flash message' do
      resend_mfa

      expect(flash[:notice]).to include("MFA has been sent via SMS to number on file")
    end

    it 'changes mfa_randomized_token' do
      resend_mfa

      expect(request.session[:mfa_randomized_token]).to be_present
      expect(sessions[:mfa_randomized_token]).not_to eq(session[:mfa_randomized_token])
    end

    context 'when resend fails' do
      before { allow(TwilioHelper).to receive(:send_sms).and_raise(StandardError, 'Oops') }
      it 'correctly redirects' do
        resend_mfa

        expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
      end

      it 'sets flash message' do
        resend_mfa

        expect(flash[:alert]).to include("Failed to send sms")
      end

      it 'changes mfa_randomized_token' do
        resend_mfa

        expect(session[:mfa_randomized_token]).to be_nil
      end
    end

    include_examples 'when invalid token'
  end
end
