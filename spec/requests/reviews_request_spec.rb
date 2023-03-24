require "rails_helper"

base_url = "/reviews"
RSpec.describe base_url, type: :request do
  let!(:topic_review) { FactoryBot.create(:topic_review) }

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
  end
end
