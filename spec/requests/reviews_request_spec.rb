require "rails_helper"

base_url = "/reviews"
RSpec.describe base_url, type: :request do
  let!(:topic_review) { FactoryBot.create(:topic_review) }

  describe "show" do
    it "redirects" do
      get "#{base_url}/#{topic_review.slug}"
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq "#{base_url}/#{topic_review.slug}"
    end
  end

  context "index" do
    it "renders" do
      get base_url
      expect(response.code).to eq "200"
      expect(response).to render_template("reviews/index")
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user
    describe "index" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/index")
      end
    end

    describe "show" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/index")
      end
    end
  end
end
