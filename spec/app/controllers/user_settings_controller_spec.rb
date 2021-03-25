require 'twilio_helper'

RSpec.describe RailsBase::UserSettingsController, type: :controller do
  let(:user) { User.first }
  let(:params) { { user: user_params } }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in(user)
  end

  shared_examples 'not signed in' do
    context 'when not signed in' do
      before { sign_out(user) }

      it 'redirects to session login' do
        subject

        expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
      end
    end
  end

  describe 'POST #edit_name' do
    subject(:edit_name) { post(:edit_name, params: params) }

    let(:user_params) { { first_name: first_name, last_name: last_name } }
    let(:first_name) { "New First' Name" }
    let(:last_name) { 'New Last Name' }
    let(:name_change) { "#{first_name} #{last_name}" }
    context 'when hit velocity limit' do
    end

    context 'when invalid names' do
      shared_examples 'invalid names' do
        it { expect { edit_name }.not_to change { user.reload.full_name } }

        it 'redirects correctly' do
          edit_name

          expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
        end

        it 'sets flash correctly' do
          edit_name

          expect(flash[:alert]).to include(flash_msg)
        end
      end

      context 'when name > max length' do
        let(:first_name) { 'm' * ( RailsBase::Authentication::Constants::MAX_NAME + 1) }
        let(:flash_msg) { 'First Name validation: Too many characters' }

        include_examples 'invalid names'
      end

      context 'when name < min length' do
        let(:first_name) { 'm' * ( RailsBase::Authentication::Constants::MIN_NAME - 1) }
        let(:flash_msg) { 'First Name validation: Too few characters' }

        include_examples 'invalid names'
      end

      context 'when name contains invalid characters' do
        context 'with fun case' do
          let(:first_name) { 'Unrecorgnized name🐟' }
          let(:flash_msg) { 'First Name validation: Value can not contain' }

          include_examples 'invalid names'
        end

        context 'with resonable case' do
          let(:first_name) { 'Name is invalid 1' }
          let(:flash_msg) { 'First Name validation: Value can not contain' }

          include_examples 'invalid names'
        end
      end
    end

    it 'sends email' do
      expect { edit_name }.to change {  ::ActionMailer::Base.deliveries.count }.by(1)
    end

    it { expect { edit_name }.to change { user.reload.full_name }.from(user.full_name).to(name_change) }

    it 'redirects correctly' do
      edit_name

      expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
    end

    it 'sets flash correctly' do
      edit_name

      expect(flash[:notice]).to include("Name change succesful to #{name_change}")
    end

    include_examples 'not signed in'
  end

  describe 'POST #confirm_password' do
    subject(:confirm_password) { post(:confirm_password, params: params, session: session) }

    let(:reason) { :password_flow }
    let(:params) { super().merge(reason: reason) }
    let(:user_params) { { password: 'password1' } }

    context 'when incorrect password reason' do
      let(:reason) { 'invalid_reason' }

      it 'renders teapot' do
        subject

        expect(response.status).to eq(418)
        expect(JSON.parse(response.body)['msg']).to include('invalid parameter')
      end
    end

    it 'sends html as json' do
      confirm_password

      expect(JSON.parse(response.body).keys).to include('html')
    end

    it 'renders html' do
      expect_any_instance_of(described_class).to receive(:render_to_string)
        .with(partial: 'rails_base/user_settings/modify_password_update_password')

      confirm_password
    end

    context 'with incorrect password' do
      let(:user_params) { { password: 'not the correct password' } }
      it 'sends html as json' do
        confirm_password

        expect(JSON.parse(response.body).keys).to include('msg')
        expect(JSON.parse(response.body)['msg']).to include('Incorrect credentials.')
      end
    end

    include_examples 'not signed in'
  end

  describe 'POST #edit_password' do
    subject(:edit_password) { post(:edit_password, params: params) }

    let(:user_params) { { password: password, password_confirmation: password_confirmation } }
    let(:password) { 'thisismynewsecurepassword1' }
    let(:password_confirmation) { password }

    it 'redirects correctly' do
      edit_password

      expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
    end

    it { expect { edit_password }.to change { user.reload.encrypted_password } }

    it do
      edit_password

      expect(user.reload.valid_password?(password)).to be true
    end

    it 'sets flash correctly' do
      edit_password

      expect(flash[:notice]).to include('Succesfully changed password')
    end

    context 'when password fails validation' do
      shared_examples 'password validation failures' do
        it 'sets flash correctly' do
          edit_password

          expect(flash[:alert]).to include(flash_msg)
        end

        it { expect { edit_password }.not_to change { user.reload.encrypted_password } }

        it 'redirects correctly' do
          edit_password

          expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
        end
      end

      context 'when confirmation does not match' do
        let(:password_confirmation) { "InvalidConfirmation2" }
        let(:flash_msg) { 'Passwords do not match' }

        include_examples 'password validation failures'
      end

      context 'with apostrophe' do
        let(:password) { "'UnacaptableChars1" }
        let(:flash_msg) { 'Unaccepted characters received' }

        include_examples 'password validation failures'
      end

      context 'with no number' do
        let(:password) { "NotAvalidPassword" }
        let(:flash_msg) { 'Password must contain at least 1 numbers' }

        include_examples 'password validation failures'
      end

      context 'when not long enough' do
        let(:password) { '1' + 's' * (RailsBase::Authentication::Constants::MP_MIN_LENGTH - 2) }
        let(:flash_msg) { RailsBase::Authentication::Constants::MP_REQ_MESSAGE }

        include_examples 'password validation failures'
      end
    end

    include_examples 'not signed in'
  end

  describe 'POST #destroy_user' do
    subject(:destroy_user) { post(:destroy_user, params: params) }

    let!(:datum) do
      ShortLivedData.create_data_key(
        user: user,
        max_use: max_use,
        reason: described_class::DATUM_REASON,
        ttl: described_class::DATUM_TTL,
        length: described_class::DATUM_LENGTH,
      )
    end
    let(:email) { user.email }
    let(:max_use) { 1 }
    let(:params) { { data: datum.data } }
    before do
      user.update_attributes(
        mfa_enabled: true,
        email_validated: true,
        last_mfa_login: Time.now,
      )
    end

    context 'when datum is invalid' do
      let(:max_use) { 0 }

      it 'redirects correctly' do
        destroy_user

        expect(response).to redirect_to(RailsBase.url_routes.user_settings_path)
      end

      it 'sets flash correctly' do
        destroy_user

        expect(flash[:alert]).to include('Errors with Destroy User token')
      end
    end

    it 'redirects correctly' do
      destroy_user

      expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
    end


    it 'sets flash correctly' do
      destroy_user

      expect(flash[:notice]).to eq(I18n.t('user_setting.destroy_user.soft'))
    end

    it 'sets soft destroy' do
      expect { destroy_user }.to change { user.reload.last_mfa_login }.to(nil)
        .and change { user.reload.mfa_enabled }.to(false)
        .and change { user.reload.email_validated }.to(false)
        .and change { user.reload.encrypted_password }.to('')
        .and change { user.reload.phone_number }.to(nil)
    end

    include_examples 'not signed in'
  end
end
