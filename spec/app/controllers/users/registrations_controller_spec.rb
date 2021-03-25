require 'twilio_helper'

RSpec.describe RailsBase::Users::RegistrationsController, type: :controller do
  let(:sessions) { { } }
  let(:email) { 'some_random_person@not_a_domain.app' }
  let(:first_name) { 'FirstName' }
  let(:last_name) { 'LastName' }
  let(:password) { 'password1' }
  let(:password_confirmation) { password }
  let(:sign_up_params) { { email: email, first_name: first_name, last_name: last_name, password: password, password_confirmation: password_confirmation } }
  let(:params) { { user: sign_up_params } }
  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  describe 'POST #create' do
    subject(:create) { post(:create,  params: params) }

    context 'when user already registered' do
      let(:email) { User.first.email }

      it 'redirects user to login' do
        create

        expect(response).to redirect_to(RailsBase.url_routes.new_user_session_path)
      end

      it 'correctly sets flash' do
        create

        expect(flash[:notice]).to include('Credentials exist. Please login or click forgot Password')
      end
    end

    context 'when validations fail' do
      shared_examples 'bad user form validations' do
        it 'redirects correctly' do
          create

          expect(response).to render_template(:new)
        end

        it 'sets flash' do
          create

          expect(flash[:error]).to be_present
        end

        it 'sets alert_errors' do
          create

          expect(assigns(:alert_errors)).to be_a(Hash)
        end

        it 'sets resource' do
          create

          expect(assigns(:resource_name)).to be_a(Symbol)
          expect(assigns(:resource)).to be_a(User)
        end

        it 'errors correctly identified' do
          create

          expect(assigns(:alert_errors).keys).to eq(alert_error_keys)
        end
      end

      context 'when last name contains unaccaptable chars' do
        let(:last_name) { "123Last 'Name" }
        let(:alert_error_keys) { [:last_name] }

        include_examples 'bad user form validations'
      end

      context 'when first name contains unaccaptable chars' do
        let(:first_name) { "123First 'Name" }
        let(:alert_error_keys) { [:first_name] }

        include_examples 'bad user form validations'
      end

      context 'when passwords does not match' do
        let(:password_confirmation) { password * 2 }
        let(:alert_error_keys) { [:password] }

        include_examples 'bad user form validations'
      end

      context 'when password do not match pattern' do
        let(:alert_error_keys) { [:password] }

        context 'when password is not long enough' do
          let(:password) { 'pass' }

          include_examples 'bad user form validations'
        end

        context 'when password has unaccaptable chars' do
          let(:password) { 'pass;%^fawe123' }

          include_examples 'bad user form validations'
        end
      end

      context 'when multiple validations errors' do
        let(:password) { 'pass;%^fawe123' }
        let(:first_name) { 'fawe1234' }
        let(:last_name) { 's;gwe' }
        let(:alert_error_keys) { [:first_name, :last_name, :password] }

        include_examples 'bad user form validations'
      end
    end

    context 'when resource saves correctly' do
      it 'creates new user' do
        expect { create }.to change { User.count }.from(User.count).to(User.count+1)
      end

      it 'sends email verification' do
        expect(RailsBase::Authentication::SendVerificationEmail).to receive(:call).with(user: be_a(User), reason: RailsBase::Authentication::Constants::SVE_LOGIN_REASON)
          .and_call_original


        expect { create }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'sets mfa on session' do
        create

        expect(session[:mfa_randomized_token]).to be_present
      end

      it 'redirects to static auth' do
        create

        expect(response).to redirect_to(RailsBase.url_routes.auth_static_path)
      end

      it 'sets flash' do
        create

        expect(flash[:notice]).to include('Check email for verification email')
      end
    end

    context 'when resource fails to save' do
      before do
        allow(User).to receive(:new).and_return(user)
        allow(user).to receive(:save).and_return(false)
      end
      let(:user) { User.new }

      it 'sets resource' do
        create

        expect(assigns(:resource_name)).to be_a(Symbol)
        expect(assigns(:resource)).to be_a(User)
      end

      it 'renders new' do
        create

        expect(response).to render_template(:new)
      end
    end
  end
end
