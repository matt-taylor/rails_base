# frozen_string_literal: true

RSpec.describe RailsBase::Users::SessionsController, type: :controller do
  let(:sessions) { { } }
  let(:user) { create(:user, :sms_enabled, password: password) }
  let(:email) { user.email }
  let(:password) { 'password11' }
  let(:password_param) { password }
  let(:valid_heartbeat_response) { { 'success' => true, 'ttd' => ttd, 'ttl' => ttl, 'last_request' => last_request } }
  let(:last_request) { Time.zone.now.to_i }
  let(:ttd) { Devise.timeout_in.to_i + last_request }
  let(:ttl) { ttd - Time.zone.now.to_i }
  let(:json_response) { JSON.parse(response.body) }
  let(:devise_session) { { 'warden.user.user.session' => { 'last_request_at' => last_request }} }
  let(:browser) { Browser.new(request.user_agent) }
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    allow_any_instance_of(RailsBase::Users::SessionsController).to receive(:browser).and_return(browser)
  end

  describe 'POST #create' do
    subject(:post_create) { post(:create,  params: params, session: sessions) }

    before do
      allow(User).to receive(:find_for_authentication).and_call_original
      allow(User).to receive(:find_for_authentication).with(email: user.email).and_return(user)
      allow(TwilioHelper).to receive(:send_sms).with(message: anything, to: user.phone_number)
    end
    let(:params) { { user: user_params } }
    let(:user_params) { { email: email, password: password_param } }
    let(:sessions) { { } }

    context 'when incorrect credentials' do
      shared_examples 'incorrect credentials' do
        it 'renders new' do
          post_create

          expect(response).to render_template(:new)
        end

        it 'sets user' do
          post_create

          expect(assigns(:user)).to be_a(User)
        end

        it 'sets flash' do
          post_create

          expect(flash[:alert]).to be_present
        end
      end

      context 'with modified email' do
        context 'when missing' do
          let(:email) { nil }

          include_examples 'incorrect credentials'
        end

        context 'when empty' do
          let(:email) { '' }

          include_examples 'incorrect credentials'
        end

        context 'when incorrect' do
          let(:email) { 'this is not an email address' }

          include_examples 'incorrect credentials'
        end
      end

      context 'with modified password' do
        context 'when missing' do
          let(:password_param) { nil }

          include_examples 'incorrect credentials'
        end

        context 'when empty' do
          let(:password_param) { '' }

          include_examples 'incorrect credentials'
        end

        context 'when incorrect' do
          let(:password_param) { 'this is not a password' }

          include_examples 'incorrect credentials'
        end
      end
    end

    context 'when email is not validated' do
      before { allow(user).to receive(:email_validated).and_return(false) }

      it 'correctly redirects' do
        post_create

        expect(response).to redirect_to(RailsBase.url_routes.auth_static_path)
      end

      it 'correctly sets mfa token' do
        post_create

        expect(session[:mfa_randomized_token]).to be_present
      end

      it 'correctly sets flash' do
        post_create

        expect(flash[:notice]).to eq RailsBase::Authentication::Constants::STATIC_WAIT_FLASH
      end

      it 'sends email' do
        expect(RailsBase::Authentication::SendVerificationEmail).to receive(:call).with(user: user, reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON)

        post_create
      end
    end

    context 'when mfa is enabled' do
      before do
        allow(user).to receive(:email_validated).and_return(true)
        allow(user).to receive(:mfa_sms_enabled).and_return(true)
      end

      context 'when mfa needs reverification' do
        before do
          allow(RailsBase.config.mfa).to receive(:reauth_strategy).and_return(RailsBase::Mfa::Strategy::EveryRequest)
        end

        it 'correctly redirects' do
          post_create

          expect(response).to redirect_to(RailsBase.url_routes.mfa_evaluation_path)
        end

        it 'correctly sets mfa token' do
          post_create

          expect(session[:mfa_randomized_token]).to be_present
        end

        it 'correctly sets flash' do
          post_create

          expect(flash[:notice]).to include('Please check your mobile device')
        end

        it 'sends mfa' do
          expect(RailsBase::Mfa::Sms::Send).to receive(:call).with(user: user).and_call_original

          post_create
        end
      end

      context 'when no reverification needed' do
        before do
          allow(RailsBase.config.mfa).to receive(:reauth_strategy).and_return(RailsBase::Mfa::Strategy::SkipEveryRequest)
        end

        it 'correctly redirects' do
          post_create

          expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
        end

        it 'correctly sets mfa token' do
          post_create

          expect(session[:mfa_randomized_token]).to be_nil
        end

        it 'correctly sets flash' do
          post_create

          expect(flash[:notice]).to include('Welcome. You have succesfully signed in')
        end
      end
    end

    context 'when mfa is disabled' do
      before do
        allow(user).to receive(:email_validated).and_return(true)
        allow(user).to receive(:mfa_sms_enabled).and_return(false)
      end

      it 'correctly redirects' do
        post_create

        expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
      end

      it 'does not set mfa token' do
        post_create

        expect(session[:mfa_randomized_token]).to be_nil
      end

      it 'correctly sets flash' do
        post_create

        expect(flash[:notice]).to include("Welcome. You have succesfully signed in.")
      end

      it 'correctly sets session' do
        post_create

        expect(session[:add_mfa_button]).to be(true)
      end
    end

    context 'when decision fails' do
      before { allow(RailsBase::Authentication::DecisionTwofaType).to receive(:call).with(user: user).and_return(mfa_decision) }
      let(:mfa_decision) { double('DecisionTwofaType', failure?: true, message: 'failure') }

      it 'correctly redirects' do
        post_create

        expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
      end

      it 'correctly sets flash' do
        post_create

        expect(flash[:alert]).to include('failure')
      end
    end
  end

  describe 'DELETE #destroy' do
    subject(:destroy) { delete(:destroy) }

    before { sign_in(user) }
    it 'correctly redirects' do
      destroy

      expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
    end

    it 'correctly sets flash' do
      destroy

      expect(flash[:notice]).to include('You have been succesfully signed out')
    end

    it 'correctly signs out' do
      # ensure user is signed in
      expect(user_signed_in?).to be(true)
      expect(current_user.id).to eq(user.id)

      destroy

      # ensure user is signed out
      expect(user_signed_in?).to be(false)
    end
  end

  describe 'GET #hearbeat_without_auth' do
    subject(:hearbeat_without_auth) { get(:hearbeat_without_auth, session: devise_session) }

    context 'when a bot' do
      before { allow(browser).to receive(:bot?).and_return(true) }

      it 'returns status' do
        subject

        expect(response.status).to eq(401)
      end

      it 'sends stats to client' do
        subject

        expect(json_response).to eq({'success' => false})
      end
    end

    # no session occurs from curl call
    context 'when no session' do
      let(:devise_session) { { } }
      it 'returns status' do
        subject

        expect(response.status).to eq(401)
      end

      it 'sends stats to client' do
        subject

        expect(json_response).to eq({'success' => false})
      end
    end

    context 'when signed in' do
      before { sign_in(user) }

      it 'returns status' do
        subject

        expect(response.status).to eq(200)
      end

      it 'sends stats to client' do
        subject

        expect(json_response).to eq(valid_heartbeat_response)
      end
    end

    context 'when signed out' do
      before { sign_out(user) }

      it 'returns status' do
        subject

        expect(response.status).to eq(401)
      end

      it 'sends stats to client' do
        subject

        expect(json_response).to eq({'success' => false})
      end
    end
  end

  describe 'POST #hearbeat_with_auth' do
    subject(:hearbeat_with_auth) { post(:hearbeat_with_auth, session: devise_session) }

    context 'when signed in' do
      before { sign_in(user) }

      it 'returns status' do
        subject

        expect(response.status).to eq(200)
      end

      it 'sends stats to client' do
        subject

        expect(json_response).to eq(valid_heartbeat_response)
      end
    end

    context 'when signed out' do
      # while this would be nice, controller specs dont go through the full middleware paradigm
      # warden/devise hoks are skipped
    end
  end

  xdescribe 'Heartbeat integration test' do
    # while this would be nice, controller specs dont go through the full middleware paradigm
    # warden/devise hoks are skipped
    # app/assets/javascripts/rails_base/sessions.js will have to be truested without verifications
  end
end
