require "rails_helper"

RSpec.describe "/", type: :request do
  describe "index" do
    it "renders" do
      get "/"
      expect(response.code).to eq "200"
      expect(response).to render_template("landing/index")
    end
    context "current_user present" do
      include_context :logged_in_as_user
      it "renders" do
        get "/"
        expect(response.code).to eq "200"
        expect(response).to render_template("landing/index")
      end
    end
  end
end
