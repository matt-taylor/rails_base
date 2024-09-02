# frozen_string_literal: true

RSpec.describe RailsBase::Users::PasswordsController, type: :controller do
  before do
     @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "#GET new" do
    subject(:new) { get(:new) }

    it do
      new
      expect(response).to render_template("rails_base/devise/passwords/new")
    end
  end

  describe "#POST create" do
    subject { get(:create, params:) }

    let(:params) { { user: { email: input_email } } }
    let(:email) { Faker::Internet.email }
    let(:input_email) { email }
    let!(:user) { create(:user, email:) }

    context "when email does not exist" do
      let(:input_email) { "email that does not exist" }

      it do
        subject

        expect(response).to redirect_to(RailsBase.url_routes.new_user_password_path)
      end

      it do
        subject

        expect(flash[:alert]).to include("Failed to send forget password")
      end
    end

    it do
      subject

      expect(response).to redirect_to(RailsBase.url_routes.new_user_password_path)
    end

    it do
      subject

      expect(flash[:notice]).to include("You should receive an email shortly")
    end
  end
end
