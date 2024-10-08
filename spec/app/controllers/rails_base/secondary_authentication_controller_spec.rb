require 'twilio_helper'

RSpec.describe RailsBase::SecondaryAuthenticationController, type: :controller do
  let(:user) { User.first }
  let(:sessions) { { mfa_randomized_token: mfa_randomized_token } }
  let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, expires_at: expires_at).encrypted_val }
  let(:expires_at) { Time.zone.now + 5.minutes }

  shared_examples 'invalid token context' do
    context 'when token is invalid' do
      let(:expires_at) { Time.zone.now - 1.minute }
      let(:redirect_path) { RailsBase.url_routes.new_user_session_path }
      it 'redirects correctly' do
        subject

        expect(response).to redirect_to(redirect_path)
      end

      it 'sets flash message' do
        subject

        expect(flash[:alert]).to include('Authorization token has expired')
      end
    end

    context 'when token is missing' do
      let(:sessions) { {} }
      let(:redirect_path) { RailsBase.url_routes.new_user_session_path }

      it 'redirects correctly' do
        subject

        expect(response).to redirect_to(redirect_path)
      end

      it 'sets flash message' do
        subject

        expect(flash[:alert]).to include('Authorization token not present')
      end
    end
  end

  shared_examples 'user is not logged in json' do
    context 'when user is not logged in' do
      before { sign_out(user) }

      it 'does not update' do
        expect { subject }.not_to change { change_proc.call }
      end

      it 'renders correctly' do
        subject

        expect(JSON.parse(response.body)).to include({'error' => 'Unauthorized'})
        expect(response.status).to eq(401)
      end
    end
  end

  shared_examples 'user is not logged' do
    context 'when user is not logged in' do
      before { sign_out(user) }

      it 'does not update' do
        expect { subject }.not_to change { change_proc.call }
      end

      it 'renders correctly' do
        subject

        expect(response).to redirect_to RailsBase.url_routes.unauthenticated_root_path
      end
    end
  end

  describe 'GET #static' do
    subject(:static) { get(:static, session: sessions, flash: flashes) }

    let(:flashes) { nil }
    let(:mfa_randomized_token) do
      RailsBase::Mfa::EncryptToken.call(
        user: user,
        expires_at: expires_at,
        purpose: RailsBase::Authentication::Constants::SSOVE_PURPOSE
      ).encrypted_val
    end

    context 'when flash is already present' do
      let(:notice) { 'hello. Page was reloaded. Resent the same flash' }
      let(:flashes) { {notice: notice} }

      it 'renders correctly' do
        static

        expect(response).to render_template(:static)
      end

      it 'sets flash message' do
        static

        expect(flash[:notice]).to include(notice)
      end
    end

    it 'renders correctly' do
      static

      expect(response).to render_template(:static)
    end

    it 'sets flash message' do
      static

      expect(flash[:notice]).to include(RailsBase::Authentication::Constants::STATIC_WAIT_FLASH)
    end

    include_examples 'invalid token context'
  end

  describe 'POST #resend_email' do
    subject(:resend_email) { post(:resend_email, session: sessions) }

    it 'sends email with correct params' do
      expect(RailsBase::Authentication::SendVerificationEmail).to receive(:call).with(user: be_a(User), reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON).and_call_original

      resend_email
    end

    it 'delivers email' do
      expect { resend_email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'redirects correctly' do
      resend_email

      expect(response).to redirect_to(RailsBase.url_routes.auth_static_path)
    end

    it 'sets flash message' do
      resend_email

      expect(flash[:notice]).to include("Verification Email resent to #{user.email}")
    end

    context 'when email verification fails' do
      let(:instance) { described_class.new(params) }
      before do
        # force it to fail without stubbing
        instance = RailsBase::Authentication::SendVerificationEmail.new(user: user, reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON)
        instance.vl_write!(Array.new(instance.velocity_max, Time.zone.now))
      end

      it 'redirects correctly' do
        resend_email

        expect(response).to redirect_to(RailsBase.url_routes.auth_static_path)
      end

      it 'sets flash message' do
        resend_email

        expect(flash[:alert]).to include('Velocity limit reached for SMS verification')
      end
    end

    include_examples 'invalid token context'
  end

  describe 'POST #email_verification' do
    subject(:email_verification) { post(:email_verification, params: params) }
    let(:params) { { data: data } }
    let(:data) { datum.data }
    let!(:datum) do
      ShortLivedData.create_data_key(
        user: user,
        max_use: 1,
        reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON,
        length: RailsBase::Authentication::Constants::EMAIL_LENGTH,
      )
    end

    context 'when data is invalid' do
      context 'when data is incorrect' do
        let(:data) { 'not a correct value' }
        it 'redirects correctly' do
          email_verification

          expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
        end

        it 'sets flash message' do
          email_verification

          expect(flash[:alert]).to include('Invalid Email Verification Code')
        end
      end

      context 'when used more than once' do
        before { datum.add_access_count! }

        it 'redirects correctly' do
          email_verification

          expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
        end

        it 'sets flash message' do
          email_verification

          expect(flash[:alert]).to include('Errors with Email Verification: too many uses')
        end
      end
    end

    it { expect { email_verification }.to change{ user.reload.email_validated }.to(true) }

    it 'validates data param' do
      expect(RailsBase::Authentication::SsoVerifyEmail).to receive(:call).with(verification: data).and_call_original

      email_verification
    end

    it 'redirects correctly' do
      email_verification

      expect(response).to redirect_to(RailsBase.url_routes.login_after_email_path)
    end

    it 'sets mfa_randomized_token' do
      email_verification

      expect(session[:mfa_randomized_token]).to be_present
    end
  end

  describe 'GET #after_email_login_session_new' do
    subject(:after_email_login_session_new) { get(:after_email_login_session_new, session: sessions, flash: flashes) }
    let(:flashes) { nil }
    let(:mfa_randomized_token) do
      RailsBase::Mfa::EncryptToken.call(
        user: user,
        expires_at: expires_at,
        purpose: RailsBase::Authentication::Constants::SSOVE_PURPOSE
      ).encrypted_val
    end

    context 'when flash is already present' do
      let(:notice) { 'hello. Page was reloaded. Resent the same flash' }
      let(:flashes) { { notice: notice } }

      it 'renders correctly' do
        after_email_login_session_new

        expect(response).to render_template(:after_email_login_session_new)
      end

      it 'sets flash message' do
        after_email_login_session_new

        expect(flash[:notice]).to include(notice)
      end
    end

    it 'renders correctly' do
      after_email_login_session_new

      expect(response).to render_template(:after_email_login_session_new)
    end

    it 'sets flash message' do
      after_email_login_session_new

      expect(flash[:notice]).to include('Email has been verified. Please Log in again to gain access')
    end

    include_examples 'invalid token context'
  end

  describe 'POST #after_email_login_session_create' do
    subject(:after_email_login_session_create) { post(:after_email_login_session_create, session: sessions, params: params) }

    let(:params) { { user: user_params} }
    let(:user_params) { { email: email, password: password } }
    let(:email) { user.email }
    let(:password) { 'password11' }
    let(:mfa_randomized_token) do
      RailsBase::Mfa::EncryptToken.call(
        user: user,
        expires_at: expires_at,
        purpose: RailsBase::Authentication::Constants::SSOVE_PURPOSE
      ).encrypted_val
    end

    shared_examples 'incorrect credentials' do
      it 'redirects correctly' do
        after_email_login_session_create

        expect(response).to render_template(:after_email_login_session_new)
      end

      it 'sets flash message' do
        after_email_login_session_create

        expect(flash[:alert]).to include('Incorrect credentials. Please try again')
      end

      it 'assigns user' do
        after_email_login_session_create

        expect(assigns(:user).email).to eq(email)
      end
    end

    context 'when incorrect password' do
      let(:password) { 'incorrect password for user' }

      include_examples 'incorrect credentials'
    end

    context 'when incorrect email' do
      let(:email) { 'not an existing email' }

      include_examples 'incorrect credentials'
    end

    it 'correctly redirects' do
      after_email_login_session_create

      expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
    end

    it 'correctly sets flash' do
      after_email_login_session_create

      expect(flash[:notice]).to include('Welcome. You have succesfully logged in')
    end

    it 'logs user in' do
      expect(user_signed_in?).to be(false)
      expect(request.session["warden.user.user.key"]).to be_nil

      after_email_login_session_create

      expect(user_signed_in?).to be(true)
    end

    include_examples 'invalid token context'
  end

  describe 'GET #forgot_password' do
    subject(:forgot_password) { get(:forgot_password, params: params) }

    let(:user) { create(:user) }
    let!(:datum) do
      ShortLivedData.create_data_key(
        user: user,
        max_use: 1,
        reason: RailsBase::Authentication::Constants::VFP_REASON,
        length: RailsBase::Authentication::Constants::EMAIL_LENGTH,
      )
    end
    let(:params) { { data: data } }
    let(:data)  { datum.data }

    context 'when mfa is enabled' do
      let(:user) { create(:user, :totp_enabled) }

      it do
        forgot_password

        expect(response).to redirect_to(RailsBase.url_routes.mfa_with_event_path(mfa_event: :forgot_password))
      end

      it "sets mfa_event in session" do
        forgot_password

        expect(mfe_events_from_session).to include("forgot_password")
      end

      it "sets flash" do
        forgot_password

        expect(flash[:notice]).to eq("MFA required to reset password")
      end
    end

    context "when mfa is disabled" do
      let(:user) { create(:user) }

      it do
        forgot_password

        expect(response).to redirect_to(RailsBase.url_routes.reset_password_input_path(data: data))
      end

      it "sets mfa_event in session" do
        forgot_password

        expect(mfe_events_from_session).to include("forgot_password")
      end

      it "satiates mfa_event in session" do
        forgot_password

        expect(mfa_event_from_session(event_name: "forgot_password").satiated?).to eq(true)
      end

      it "sets flash" do
        forgot_password

        expect(flash[:notice]).to eq("Datum valid. Reset your password")
      end
    end

    context 'when VerifyForgotPassword fails' do
      context 'when incorrect datum' do
        let(:data)  { datum.data + '0' }

        it 'redirect correctly' do
          forgot_password

          expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
        end

        it 'sets flash' do
          forgot_password

          expect(flash[:alert]).to include(RailsBase::Authentication::Constants::MV_FISHY)
        end
      end

      context 'when datum already used' do
        before { datum.add_access_count! }

        it 'redirect correctly' do
          forgot_password

          expect(response).to redirect_to(RailsBase.url_routes.new_user_password_path)
        end

        it 'sets flash' do
          forgot_password

          expect(flash[:alert]).to include('Errors with email validation: too many uses')
        end
      end
    end
  end

  describe "#GET reset_password_input" do
    subject(:reset_password_input) { get(:reset_password_input, params: { data: }, session: mfa_event_session_hash(mfa_event:)) }

    let(:mfa_event) { RailsBase::MfaEvent.forgot_password(user:, data:)  }
    let!(:datum) do
      ShortLivedData.create_data_key(
        user: user,
        max_use: 1,
        reason: RailsBase::Authentication::Constants::VFP_REASON,
        length: RailsBase::Authentication::Constants::EMAIL_LENGTH,
      )
    end
    let(:data)  { datum.data }

    context "with invalid mfa event" do
      context "with wrong event set" do
        let(:mfa_event) { RailsBase::MfaEvent.sms_enable(user:)  }

        it do
          reset_password_input

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          reset_password_input

          expect(flash[:alert]).to include("Unauthorized MFA event")
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        it do
          reset_password_input

          expect(flash[:alert]).to include("MFA event for forgot_password")
        end

        it do
          reset_password_input

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end
      end
    end

    context "when mfa_event is not satiated" do
      it do
        reset_password_input

        expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
      end

      it do
        reset_password_input

        expect(flash[:alert]).to include("Unauthorized access")
      end
    end

    context "when mfa_event is satiated" do
      before { mfa_event.satiated! }

      it do
        reset_password_input

        expect(response).to render_template(:reset_password_input)
      end
    end
  end

  describe 'POST #reset_password' do
    subject(:reset_password) { post(:reset_password, session:  mfa_event_session_hash(mfa_event:), params:) }

    before { mfa_event.satiated! if satiate_event }

    let(:mfa_event) { RailsBase::MfaEvent.forgot_password(user:, data:)  }
    let(:satiate_event) { true }
    let(:params) { { data: data, user: user_params } }
    let(:data) { datum.data }
    let!(:datum) do
      ShortLivedData.create_data_key(
        user: user,
        max_use: 1,
        reason: RailsBase::Authentication::Constants::VFP_REASON,
        length: RailsBase::Authentication::Constants::EMAIL_LENGTH,
      )
    end

    let(:user_params) { { password: password, password_confirmation: password_confirmation } }
    let(:password) { 'password1234' }
    let(:password_confirmation) { password }
    shared_examples 'password reset_fails' do
      it 'redirects correctly' do
        subject

        expect(response).to redirect_to(RailsBase.url_routes.new_user_password_path)
      end

      it 'sets the flash' do
        subject

        expect(flash[:alert]).to include(flash_msg)
      end

      it 'does not change password' do
        expect { subject }.not_to change { user.reload.encrypted_password }
      end
    end

    context "with invalid mfa event" do
      context "with wrong event set" do
        let(:mfa_event) { RailsBase::MfaEvent.sms_enable(user:)  }

        it do
          reset_password

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          reset_password

          expect(flash[:alert]).to include("Unauthorized MFA event")
        end
      end

      context "with expired event" do
        before { Timecop.travel(mfa_event.death_time + 1.minute) }

        it do
          reset_password

          expect(flash[:alert]).to include("MFA event for forgot_password")
        end

        it do
          reset_password

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end
      end
    end

    context 'when password is invalid' do
      context 'when passwords do not match' do
        let(:password_confirmation) { password + '1' }
        let(:flash_msg) { 'Passwords do not match. Retry password flow' }

        include_examples 'password reset_fails'
      end

      context 'when password does not meet criteria' do
        let(:password) { 'invalid chars 11√"'}
        let(:flash_msg) { 'Unaccepted characters received. Characters must be in [0-9a-zA-Z]' }

        include_examples 'password reset_fails'
      end
    end

    context 'when invalid data point' do
      let(:data) { super() + '1' }
      let(:flash_msg) { RailsBase::Authentication::Constants::MV_FISHY }

      include_examples 'password reset_fails'
    end

    context "when mfa_event is not satiated" do
      let(:satiate_event) { false }

      it "sets the flash" do
        reset_password

        expect(flash[:alert]).to include("Unauthorized access")
      end

      it do
        reset_password

        expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
      end
    end

    it do
      reset_password

      expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
    end

    it 'sets the flash' do
      reset_password

      expect(flash[:notice]).to include('Password succesfully changed. Please login')
    end

    it 'changes password' do
      expect { reset_password }.to change { user.reload.encrypted_password }
    end
  end

  describe 'GET #sso_login' do
    subject(:sso_login) { post(:sso_login, params: { data: data }) }

    before { sign_out(user) }
    let(:data) { sso_datum.data }
    let(:user) { User.first }
    let(:uses) { nil }
    let(:expires_at) { 5.minutes.from_now }
    let(:reason) { RailsBase::Authentication::Constants::SSO_LOGIN_REASON }
    let(:url_redirect) { nil }
    let(:datum_params) do
      {
        user: user,
        token_length: 32,
        uses: uses,
        expires_at: expires_at,
        reason: reason,
        url_redirect: url_redirect,
      }.compact
    end
    let!(:sso_datum) { RailsBase::Authentication::SingleSignOnCreate.call(datum_params).data }

    shared_examples 'naming is hard when your high' do
      it 'redirects correctly' do
        subject

        expect(response).to redirect_to(expected_url)
      end

      it 'sets flash message' do
        subject

        expect(flash[:notice]).to eq(I18n.t('authentication.sso_login.valid'))
      end

      it 'signs in user' do
        subject

        expect(controller.current_user).to eq user
      end
    end

    shared_examples 'SSO successful eamples' do
      let(:expected_url) { RailsBase.url_routes.authenticated_root_path }
      context 'with invalid url' do
        let(:url_redirect) { 'not a valid path' }

        include_examples 'naming is hard when your high'
      end

      context 'with valid url' do
        let(:url_redirect) { RailsBase.url_routes.user_settings_path }
        let(:expected_url) { url_redirect }

        include_examples 'naming is hard when your high'
      end

      context 'with no url' do
        include_examples 'naming is hard when your high'
      end
    end

    context 'when SSO verify succeeds' do
      context 'when user signed in' do
        before { sign_in(user) }

        include_examples 'SSO successful eamples'
      end

      context 'when user signed out' do
        include_examples 'SSO successful eamples'
      end
    end

    context 'when sso verify fails' do
      let(:uses) { 0 }

      context 'when user signed in' do
        before do
          allow(Rails.logger).to receive(:info)
          sign_in(user)
        end

        it 'sends logging message' do
          expect(Rails.logger).to receive(:info).with('User is logged in but failed the SSO login')

          subject
        end

        include_examples 'SSO successful eamples'
      end

      context 'when user signed out' do
        it 'redirects correctly' do
          subject

          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it 'sets the flash' do
          subject

          expect(flash[:alert]).to include(I18n.t('authentication.sso_login.fail'))
        end
      end
    end
  end
end
