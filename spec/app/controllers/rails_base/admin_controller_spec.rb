# frozen_string_literal: true

require "twilio_helper"

RSpec.describe RailsBase::AdminController, type: :controller do
  before do
    sign_in(user) if sign_in_user
    allow(TwilioHelper).to receive(:send_sms)
  end

  let(:user) { create(:user, :admin_owner) }
  let(:sign_in_user) { true }

  describe "#GET index" do
    subject(:index) { get(:index) }

    it do
      index

      expect(response).to render_template(:index)
    end
  end

  describe "#GET show_config" do
    subject(:show_config) { get(:show_config) }

    it do
      show_config

      expect(response).to render_template(:show_config)
    end

    context "without permissions" do
      let(:user) { create(:user) }

      it do
        show_config

        expect(flash[:alert]).to include("You do not have correct permissions")
        expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
      end
    end
  end

  describe "#POST sso_send" do
    subject(:sso_send) { post(:sso_send, params: {id:}) }
    let(:id) { user.id }

    context "without permissions" do
      let(:user) { create(:user, :admin_view) }

      it do
        sso_send

        expect(flash[:alert]).to include("You do not have correct permissions")
        expect(response).to redirect_to(RailsBase.url_routes.admin_base_path)
      end
    end

    context "with sso_send failure" do
      before do
        allow(RailsBase::Authentication::SingleSignOnCreate).to receive(:call).with(anything).and_return(sso_create)
      end

      let(:sso_create) { double('RailsBase::Authentication::SingleSignOnCreate', failure?: true) }

      it do
        sso_send

        expect(flash[:alert]).to include("Failed to send SSO")
        expect(response).to redirect_to(RailsBase.url_routes.admin_base_path)
      end
    end

    it do
      sso_send

      expect(flash[:notice]).to include("Successfully sent SSO")
      expect(response).to redirect_to(RailsBase.url_routes.admin_base_path)
    end
  end

  # TODO: Move this to a different controller
  describe "#POST sso_retrieve" do
    subject (:sso_retrieve) { get(:sso_retrieve, params: {data:}) }

    let(:data) do
      local_params = {
        user: user,
        token_length: RailsBase::Authentication::Constants::SSO_SEND_LENGTH,
        uses: RailsBase::Authentication::Constants::SSO_SEND_USES,
        reason: RailsBase::Authentication::Constants::SSO_REASON,
        expires_at: RailsBase::Authentication::Constants::SSO_EXPIRES.from_now,
        url_redirect: RailsBase.url_routes.authenticated_root_path
      }

      RailsBase::Authentication::SingleSignOnCreate.(**local_params).data.data
    end

    context "when user is signed in" do
      context "when sso_verify fails" do
        let(:data) { "incorrect_data_string" }

        it do
          sso_retrieve
          expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
        end

        it do
          sso_retrieve
          expect(flash[:notice]).to include("SSO failed but you are already logged in")
        end
      end

      context "when sso_verify succeeds" do
        it do
          sso_retrieve
          expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
        end

        it do
          sso_retrieve
          expect(flash[:notice]).to include("SSO success. You are already logged in")
        end
      end
    end

    context "when user is not signed in" do
      let(:sign_in_user) { false }

      context "when sso_verify fails" do
        let(:data) { "incorrect_data_string" }

        it do
          sso_retrieve
          expect(response).to redirect_to(RailsBase.url_routes.unauthenticated_root_path)
        end

        it do
          sso_retrieve
          expect(flash[:alert]).to include("SSO login failed")
        end
      end

      context "when sso_verify succeeds" do
        it do
          sso_retrieve
          expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
        end

        it do
          sso_retrieve
          expect(flash[:notice]).to include("SSO success. You are now logged in")
        end
      end
    end
  end

  describe "#POST ack" do
    subject(:ack) { post(:ack) }

    context "with failure" do
      before do
        allow(RailsBase::Admin::ActionCache.instance).to receive(:delete_actions_since!).and_raise(StandardError)
      end

      it do
        ack

        expect(response.status).to eq(500)
      end
    end

    it "clears cache" do
      expect(RailsBase::Admin::ActionCache.instance).to receive(:delete_actions_since!).and_call_original

      ack
    end

    it do
      ack

      expect(response.status).to eq(200)
    end
  end

  describe "#GET history" do
    subject(:history) { get(:history) }

    context "without permissions" do
      before do
        allow(RailsBase.config.admin).to receive(:enable_history_by_user?).with(anything).and_return(false)
      end

      it do
        history

        expect(response).to redirect_to(RailsBase.url_routes.authenticated_root_path)
      end

      it do
        history

        expect(flash[:alert]).to include("You do not have correct permissions to view admin history")
      end
    end

    it do
      history

      expect(response).to render_template(:history)
    end

    it do
      history

      expect(session[:rails_base_paginate_start_user]).to be_present
      expect(session[:rails_base_paginate_start_admin]).to be_present
    end
  end

  describe "#POST update_name" do
    subject(:update_name) { post(:update_name, params: params, session: session)}

    let(:params) { {first_name:, last_name:, id:} }
    let(:id) { user.id }
    let(:first_name) { Faker::Name.first_name }
    let(:last_name) { Faker::Name.first_name }
    let(:reason) {  "#{RailsBase::AdminHelper::SESSION_REASON_BASE}-#{SecureRandom.uuid}" }
    let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, purpose: reason, expires_at: 1.minute.from_now).encrypted_val }
    let(:session) do
      {
        RailsBase::AdminHelper::SESSION_REASON_KEY => reason,
        mfa_randomized_token: mfa_randomized_token
      }
    end

    context "with unauthorized user" do
      let(:user) { create(:user) }

      it do
        update_name

        expect(response.status).to eq(404)
      end

      it do
        update_name

        expect(response.body).to include("Unauthorized action. You have been signed out")
      end
    end

    context "when admin update fails" do
      before do
        allow_any_instance_of(RailsBase::NameChange).to receive(:validate_full_name?).and_return({ status: false, errors: {}})
      end

      it do
        update_name

        expect(response.status).to eq(404)
      end

      it do
        update_name

        expect(response.body).to include("Failed to change #{user.id} name")
      end
    end

    it do
      update_name

      expect(response.status).to eq(200)
    end

    it do
      update_name

      expect(response.body).to include("Successfully changed name")
    end

    it do
      expect { update_name }.to change { user.reload.full_name }.from(user.full_name).to("#{first_name} #{last_name}")
    end
  end

  describe "#POST update_email" do
    subject(:update_email) { post(:update_email, params: params, session: session)}

    let(:params) { {email:, id:} }
    let(:id) { user.id }
    let(:email) { Faker::Internet.email }
    let(:reason) {  "#{RailsBase::AdminHelper::SESSION_REASON_BASE}-#{SecureRandom.uuid}" }
    let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, purpose: reason, expires_at: 1.minute.from_now).encrypted_val }
    let(:session) do
      {
        RailsBase::AdminHelper::SESSION_REASON_KEY => reason,
        mfa_randomized_token: mfa_randomized_token
      }
    end

    context "with unauthorized user" do
      let(:user) { create(:user) }

      it do
        update_email

        expect(response.status).to eq(404)
      end

      it do
        update_email

        expect(response.body).to include("Unauthorized action. You have been signed out")
      end
    end

    context "when admin update fails" do
      before do
        allow(RailsBase::EmailChange).to receive(:call).with(anything).and_return(sso_create)
      end

      let(:sso_create) { double("RailsBase::EmailChange", success?: false, failure?: true, message: "Unable to update email address") }

      it do
        update_email

        expect(response.status).to eq(404)
      end

      it do
        update_email

        expect(response.body).to include("Unable to update email address")
      end
    end

    it do
      update_email

      expect(response.status).to eq(200)
    end

    it do
      update_email

      expect(response.body).to include("Successfully changed email")
    end

    it do
      expect { update_email }.to change { user.reload.email }.from(user.email).to(email)
    end
  end

  describe "#POST update_phone" do
    subject(:update_phone) { post(:update_phone, params: params, session: session)}

    let(:params) { {phone_number:, id:} }
    let(:id) { user.id }
    let(:phone_number) { Faker::PhoneNumber.phone_number.gsub(/\D/,'') }
    let(:reason) {  "#{RailsBase::AdminHelper::SESSION_REASON_BASE}-#{SecureRandom.uuid}" }
    let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, purpose: reason, expires_at: 1.minute.from_now).encrypted_val }
    let(:session) do
      {
        RailsBase::AdminHelper::SESSION_REASON_KEY => reason,
        mfa_randomized_token: mfa_randomized_token
      }
    end

    context "with unauthorized user" do
      let(:user) { create(:user) }

      it do
        update_phone

        expect(response.status).to eq(400)
      end

      it do
        update_phone

        expect(response.body).to include("Unauthorized action. You have been signed out")
      end
    end

    context "when admin update fails" do
      before do
        allow(RailsBase::AdminUpdateAttribute).to receive(:call).with(anything).and_return(instance)
      end

      let(:instance) { double("RailsBase::AdminUpdateAttribute", success?: false, failure?: true, message: "Unable to update phone") }

      it do
        update_phone

        expect(response.status).to eq(404)
      end

      it do
        update_phone

        expect(response.body).to include("Unable to update phone")
      end
    end

    it do
      update_phone

      expect(response.status).to eq(200)
    end

    it do
      update_phone

      expect(response.body).to include("has changed attribute")
    end

    it do
      expect { update_phone }.to change { user.reload.phone_number }.from(user.phone_number).to(phone_number)
    end
  end

  describe "#POST send_2fa" do
    subject(:send_2fa) { post(:send_2fa, params: params, session: session)}

    let(:params) { {phone_number:, id:} }
    let(:id) { user.id }
    let(:phone_number) { Faker::PhoneNumber.phone_number.gsub(/\D/,'') }
    let(:reason) {  "#{RailsBase::AdminHelper::SESSION_REASON_BASE}-#{SecureRandom.uuid}" }
    let(:mfa_randomized_token) { RailsBase::Mfa::EncryptToken.call(user: user, purpose: reason, expires_at: 1.minute.from_now).encrypted_val }
    let(:session) do
      {
        RailsBase::AdminHelper::SESSION_REASON_KEY => reason,
        mfa_randomized_token: mfa_randomized_token
      }
    end

    context "with unauthorized user" do
      let(:user) { create(:user) }

      it do
        send_2fa

        expect(response.status).to eq(404)
      end

      it do
        send_2fa

        expect(response.body).to include("Unauthorized action. You have been signed out")
      end
    end

    context "when mfa send fails" do
      before do
        allow(RailsBase::AdminRiskyMfaSend).to receive(:call).with(anything).and_return(instance)
      end

      let(:instance) { double("RailsBase::AdminRiskyMfaSend", success?: false, failure?: true, message: "Unable to send mfa") }

      it do
        send_2fa

        expect(response.status).to eq(404)
      end

      it do
        send_2fa

        expect(response.body).to include("Unable to send mfa")
      end
    end

    it do
      send_2fa

      expect(session[RailsBase::AdminHelper::SESSION_REASON_KEY]).to be_present
    end

    it do
      send_2fa

      expect(response.status).to eq(200)
    end

    it do
      send_2fa

      expect(response.body).to include("MFA code has been succesfully")
    end
  end
end
