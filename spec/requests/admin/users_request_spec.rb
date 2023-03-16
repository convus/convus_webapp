require "rails_helper"

base_url = "/admin/users"
RSpec.describe base_url, type: :request do

  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq "/admin/users"
    end

    context "signed in" do
      include_context :logged_in_as_user
      it "flash errors" do
        get base_url
        expect(response).to redirect_to root_url
        expect(flash[:error]).to be_present
      end
    end
  end

  context "signed in as admin" do
    include_context :logged_in_as_admin
    describe "index" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/users/index")
      end
    end
  end
end
