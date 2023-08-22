require "rails_helper"

base_url = "/admin/quiz_responses"
RSpec.describe base_url, type: :request do
  let(:quiz_response) { FactoryBot.create(:quiz_response) }

  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/admin/quiz_responses"
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
        expect(quiz_response).to be_valid
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/quiz_responses/index")
        expect(assigns(:quiz_responses).pluck(:id)).to eq([quiz_response.id])
      end
    end
  end
end
