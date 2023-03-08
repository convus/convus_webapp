require "rails_helper"

RSpec.describe "user requests", type: :request do
  describe "new session" do
    it "renders" do
      get "/users/sign_in"
      expect(response.code).to eq "200"
      expect(response).to render_template("devise/sessions/new")
    end
  end

  describe "new registration" do
    it "renders" do
      get "/users/sign_up"
      expect(response.code).to eq "200"
      expect(response).to render_template("devise/registrations/new")
    end
  end

  describe "edit" do
    it "redirects" do
      get "/users/edit"
      expect(response.code).to eq "302"
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user
    describe "edit" do
      it "renders" do
        get "/users/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("devise/registrations/edit")
      end
    end

    describe "delete" do
      it "deletes user" do
        expect {
          delete "/users"
        }.to change(User, :count).by(-1)
        expect(response).to redirect_to(root_url)
      end
    end

    describe "update" do
      let(:current_user) { FactoryBot.create(:user, email: "old@example.com", password: "faketestpassword") }
      it "doesn't update without a password" do
        patch "/users", params: {user: {email: "new@example.com"}}
        expect(current_user.reload.email).to eq "old@example.com"
      end
      context "with password" do
        it "updates" do
          expect(current_user.reviews_public).to be_falsey
          patch "/users", params: {user: {
            current_password: "faketestpassword",
            password: "newpassword",
            email: "new@example.com"
          }}
          expect(current_user.reload.email).to eq "new@example.com"
          expect(current_user.valid_password?("newpassword")).to be_truthy
        end
      end
    end
  end
end
