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
        get "/", headers: {"HTTP_ORIGIN" => "*"}
        expect(response.code).to eq "200"
        expect(response).to render_template("landing/index")
        expect(response.headers["Access-Control-Allow-Origin"]).to_not be_present
      end
      # TODO: fix these tests! ESBUILD_ERROR_RENDERED isn't stubbed correctly
      # describe "esbuild_error" do
      #   before { stub_const("ApplicationController::ESBUILD_ERROR_RENDERED", true) }
      #   it "doesn't render" do
      #     get "/"
      #     expect(response.code).to eq "200"
      #     expect(response).to render_template("landing/index")
      #   end
      #   context "with esbuild_error" do
      #     it "doesn't render" do
      #       allow_any_instance_of(RenderEsbuildErrors).to receive(:error_file_content) { "Errored\nerror here" }
      #       get "/"
      #       expect(response.code).to eq "200"
      #       expect(response.body).to match("<h1>Errored</h1>")
      #     end
      #   end
      # end
    end
  end

  describe "/about" do
    it "renders" do
      get "/about"
      expect(response.code).to eq "200"
      expect(response).to render_template("landing/about")
    end
  end

  describe "/privacy" do
    it "renders" do
      get "/privacy"
      expect(response.code).to eq "200"
      expect(response).to render_template("landing/privacy")
    end
  end

  describe "/browser_extensions" do
    it "renders" do
      get "/browser_extensions"
      expect(response.code).to eq "200"
      expect(response).to render_template("landing/browser_extensions")
    end
  end
end
