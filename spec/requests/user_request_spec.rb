require "rails_helper"

RSpec.describe "user requests", type: :request do
  describe "new session" do
    it "redirects" do
      get "/users/sign_in"
      expect(response.code).to eq "200"
      expect(response).to render_template("devise/sessions/new")
    end
  end

  describe "new registration" do
    it "redirects" do
      get "/users/sign_up"
      expect(response.code).to eq "200"
      expect(response).to render_template("devise/registrations/new")
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
  end
end
