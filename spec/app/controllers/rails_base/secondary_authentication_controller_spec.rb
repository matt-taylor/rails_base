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
      expect(request.session["warden.user.user.key"]).to be_nil

      after_email_login_session_create

      expect(session["warden.user.user.key"][0]).to eq([user.id])
    end

    include_examples 'invalid token context'
  end

  describe 'POST #phone_registration json' do
    subject(:phone_registration) { post(:phone_registration,  params: params) }

    let(:params) { { phone_number: phone_number } }
    let(:phone_number) { '6508675310' }
    let(:change_proc) { -> { user.reload.phone_number } }
    before { sign_in(user) }

    context 'when UpdatePhoneSendVerification fails' do
      before { allow(TwilioHelper).to receive(:send_sms).and_raise(StandardError, 'Forced failure') }

      context 'when phone is not sanitized' do
        let(:phone_number) { 'not a phone number' }

         it 'does not update phone' do
          expect { phone_registration }.not_to change { change_proc.call }
         end

         it 'renders correctly' do
          phone_registration

          expect(JSON.parse(response.body)).to include({'error' => 'Unable to complete request'})
          expect(response.status).to eq(418)
        end
      end

      it 'updates phone' do
        expect { phone_registration }.to change { change_proc.call }
      end

      it 'renders correctly' do
        phone_registration

        expect(JSON.parse(response.body)).to include({'error' => 'Unable to complete request'})
        expect(response.status).to eq(418)
      end
    end

    it 'updates phone' do
      expect { phone_registration }.to change { change_proc.call }
    end

    it 'renders correctly' do
      phone_registration

      expect(JSON.parse(response.body)).to include({'message' => 'You are not a teapot'})
      expect(response.status).to eq(200)
    end

    include_examples 'user is not logged in json'
  end

  describe 'POST #confirm_phone_registration' do
    subject(:confirm_phone_registration) { post(:confirm_phone_registration,  params: params, session: sessions) }

    let(:mfa_params) {
      _params = {}
      RailsBase::Authentication::Constants::MFA_LENGTH.times do |index|
        var_name = "#{RailsBase::Authentication::Constants::MV_BASE_NAME}#{index}".to_sym
        _params[var_name] = mfa.split('')[index]
      end
      _params
    }
    let(:mfa) { rand.to_s[2..(2+(RailsBase::Authentication::Constants::MFA_LENGTH-1))] }
    let!(:datum) do
      ShortLivedData.create_data_key(
        user: user,
        data: mfa,
        reason: RailsBase::Authentication::Constants::MFA_REASON
      )
    end
    let(:redirect_path) { RailsBase.url_routes.authenticated_root_path }
    let(:change_proc) { -> { user.reload.mfa_sms_enabled } }
    let(:params) { { mfa: mfa_params } }
    let(:sessions) { { mfa_randomized_token: mfa_randomized_token } }

    before { sign_in(user) }

    context 'when mfa validation fails' do
      let(:mfa_params) { nil }

      it 'does not update' do
        expect { confirm_phone_registration }.not_to change { change_proc.call }
      end

      it 'renders correctly' do
        confirm_phone_registration

        expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
      end

      it 'sets flash' do
        confirm_phone_registration

        expect(flash[:alert]).to include('Unable to complete request')
      end
    end

    it 'updates mfa_sms_enabled' do
      expect { confirm_phone_registration }.to change { change_proc.call }.to(true)
    end

    it 'redirects correct' do
      confirm_phone_registration

      expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
    end

    it 'sets flash' do
      confirm_phone_registration

      expect(flash[:notice]).to eq('You have succesfully enabled 2fa.')
    end

    include_examples 'invalid token context'
  end

  describe 'DELETE #remove_phone_mfa' do
    subject(:remove_phone_mfa) { delete(:remove_phone_mfa) }
    let(:change_proc) { -> { [user.reload.mfa_sms_enabled, user.reload.last_mfa_sms_login] } }

    before do
      user.update!(mfa_sms_enabled: true, last_mfa_sms_login: Time.zone.now)
      sign_in(user)
    end

    it 'changes data' do
      expect { remove_phone_mfa }.to change { change_proc.call }

      expect(response).to redirect_to RailsBase.url_routes.authenticated_root_path
    end

    it 'sets flash' do
      remove_phone_mfa

      expect(flash[:notice]).to include('You have Disabled 2fa')
    end

    it 'redirects correctly' do
      remove_phone_mfa

      expect(response).to redirect_to RailsBase.url_routes.authenticated_root_path
    end

    include_examples 'user is not logged'
  end

  describe 'GET #forgot_password' do
    subject(:forgot_password) { get(:forgot_password, params: params) }

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
      before { user.update!(mfa_sms_enabled: true) }

      it 'sends mfa to user' do
        expect(RailsBase::Authentication::SendLoginMfaToUser).to receive(:call).with(user: user, expires_at: Time.zone.now + 10.minutes).and_call_original

        forgot_password
      end

      it 'assigns correctly' do
        forgot_password

        expect(assigns(:data)).to eq(data)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:mfa_flow)).to eq(true)
      end

      it 'sets mfa token' do
        forgot_password

        expect(session[:mfa_randomized_token]).to be_present
      end

      it 'renders correctly' do
        forgot_password

        expect(response).to render_template(:forgot_password)
      end

      it 'sets flash' do
        forgot_password

        expect(flash[:notice]).to eq('2 Factor Authentication is required for this account')
      end
    end

    it 'does not send mfa to user' do
      expect(RailsBase::Authentication::SendLoginMfaToUser).not_to receive(:call)

      forgot_password
    end

    it 'assigns correctly' do
      forgot_password

      expect(assigns(:data)).to eq(data)
      expect(assigns(:user)).to eq(user)
      expect(assigns(:mfa_flow)).to be_nil
    end

    it 'sets mfa token' do
      forgot_password

      expect(session[:mfa_randomized_token]).to be_present
    end

    it 'renders correctly' do
      forgot_password

      expect(response).to render_template(:forgot_password)
    end

    it 'sets flash' do
      forgot_password

      expect(flash[:notice]).to eq('Please enter your new password')
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

  describe 'POST #forgot_password_with_mfa' do
    subject(:forgot_password_with_mfa) { post(:forgot_password_with_mfa, params: params, session: sessions) }

    let(:mfa_params) {
      _params = {}
      RailsBase::Authentication::Constants::MFA_LENGTH.times do |index|
        var_name = "#{RailsBase::Authentication::Constants::MV_BASE_NAME}#{index}".to_sym
        _params[var_name] = mfa.split('')[index]
      end
      _params
    }
    let(:mfa) { rand.to_s[2..(2+(RailsBase::Authentication::Constants::MFA_LENGTH-1))] }
    let!(:mfa_datum) do
      ShortLivedData.create_data_key(
        user: user,
        data: mfa,
        reason: RailsBase::Authentication::Constants::MFA_REASON
      )
    end
    let!(:datum) do
      ShortLivedData.create_data_key(
        user: user,
        max_use: 1,
        reason: RailsBase::Authentication::Constants::VFP_REASON,
        length: RailsBase::Authentication::Constants::EMAIL_LENGTH,
      )
    end
    let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, expires_at: expires_at, purpose: RailsBase::Authentication::Constants::VFP_PURPOSE).encrypted_val }
    let(:data)  { datum.data }
    let(:params) { { data: data, mfa: mfa_params } }
    let(:sessions) { { mfa_randomized_token: mfa_randomized_token } }

    context 'when short lived data fails to match' do
      let(:data)  { datum.data + '0' }

      it 'redirects correctly' do
        forgot_password_with_mfa

        expect(response).to redirect_to(RailsBase.url_routes.new_user_password_path)
      end

      it 'sets flash' do
        forgot_password_with_mfa

        expect(flash[:alert]).to include('Unauthorized. Incorrect Data parameter')
      end
    end

    context 'when mfa does not match' do
      context 'when does not exist' do
        let(:mfa_params) { nil }

        it 'redirects correctly' do
          forgot_password_with_mfa

          expect(response).to redirect_to(RailsBase.url_routes.new_user_password_path)
        end

        it 'sets flash' do
          forgot_password_with_mfa

          expect(flash[:alert]).to include(RailsBase::Authentication::Constants::MV_FISHY)
        end
      end

      context 'when incorrect mfa' do
        let(:mfa_params) do
          val = super()[super().keys.first]
          super()[super().keys.first] = "#{val.to_i + 1}"
          super()
        end

        it 'redirects correctly' do
          forgot_password_with_mfa

          expect(response).to redirect_to(RailsBase.url_routes.new_user_password_path)
        end

        it 'sets flash' do
          forgot_password_with_mfa

          expect(flash[:alert]).to include('Incorrect MFA code.')
        end
      end
    end

    it 'renders correct' do
      forgot_password_with_mfa

      expect(response).to render_template(:forgot_password)
    end

    it 'assigns correct' do
      forgot_password_with_mfa

      expect(assigns(:mfa_flow)).to eq(false)
      expect(assigns(:user)).to eq(user)
    end

    it 'sets flash correct' do
      forgot_password_with_mfa

      expect(flash[:notice]).to eq('Successful MFA code. Please reset your password')
    end

    include_examples 'invalid token context'
  end

  describe 'POST #reset_password' do
    subject(:reset_password) { post(:reset_password, session: sessions, params: params) }

    let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, expires_at: expires_at, purpose: RailsBase::Authentication::Constants::VFP_PURPOSE).encrypted_val }
    let(:sessions) { { mfa_randomized_token: mfa_randomized_token } }
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

    it 'redirects correctly' do
      subject

      expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
    end

    it 'sets the flash' do
      subject

      expect(flash[:notice]).to include('Password succesfully changed. Please login')
    end

    it 'changes password' do
      expect { subject }.to change { user.reload.encrypted_password }
    end

    include_examples 'invalid token context'
  end

  describe 'GET #sso_login' do
    subject(:reset_password) { post(:sso_login, params: { data: data }) }

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
