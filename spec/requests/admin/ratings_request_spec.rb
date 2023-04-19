require "rails_helper"

base_url = "/admin/ratings"
RSpec.describe base_url, type: :request do
  let(:rating) { FactoryBot.create(:rating) }
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/admin/ratings"
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
        expect(rating).to be_valid
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/ratings/index")
        expect(assigns(:ratings).pluck(:id)).to eq([rating.id])
        # test out alphabetical sort
        get "#{base_url}?sort=name"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/ratings/index")
        expect(assigns(:ratings).pluck(:id)).to eq([rating.id])
      end
    end

    describe "show" do
      it "renders" do
        expect(rating).to be_valid
        get "#{base_url}/#{rating.id}"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/ratings/show")
      end
    end
  end
end
