require "rails_helper"

base_url = "/reviews"
RSpec.describe base_url, type: :request do
  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq "#{base_url}/new"
    end
    context "current_user present" do
      include_context :logged_in_as_user
      it "renders" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/new")
      end
    end
  end
end
