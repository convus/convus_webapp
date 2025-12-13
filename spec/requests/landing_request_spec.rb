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
      describe "RenderEsbuildErrors" do
        let(:error_file_path) { RenderEsbuildErrors.file_path }
        after { File.delete(error_file_path) if File.exist?(error_file_path) }

        it "returns empty string when no error file exists" do
          expect(File.exist?(error_file_path)).to be_falsey
          controller = ApplicationController.new
          controller.send(:extend, RenderEsbuildErrors)
          expect(controller.send(:error_file_content)).to eq("")
          expect(controller.send(:esbuild_error_present?)).to be_falsey
        end

        it "returns file content when error file exists" do
          File.write(error_file_path, "Errored\nerror here")
          controller = ApplicationController.new
          controller.send(:extend, RenderEsbuildErrors)
          expect(controller.send(:error_file_content)).to eq("Errored\nerror here")
          expect(controller.send(:esbuild_error_present?)).to be_truthy
        end
      end
    end
  end

  describe "/about" do
    it "renders" do
      get "/about"
      expect(response.code).to eq "200"
      expect(response).to render_template("landing/about")
    end
  end

  describe "/browser_extension_auth" do
    it "redirects" do
      get "/browser_extension_auth"
      expect(response).to redirect_to("/users/sign_in")
    end
    context "current_user present" do
      include_context :logged_in_as_user
      it "renders" do
        get "/browser_extension_auth"
        expect(response.code).to eq "200"
        expect(response).to render_template("landing/browser_extension_auth")
      end
    end
  end

  describe "/privacy" do
    it "renders" do
      get "/privacy"
      expect(response.code).to eq "200"
      expect(response).to render_template("landing/privacy")
    end
  end

  describe "/support" do
    it "renders" do
      get "/support"
      expect(response.code).to eq "200"
      expect(response).to render_template("landing/support")
    end
  end

  describe "/browser_extensions" do
    it "renders" do
      get "/browser_extensions"
      expect(response.code).to eq "200"
      expect(response).to render_template("landing/browser_extensions")
    end
    describe "/browser_extension" do
      it "redirects" do
        get "/browser_extension"
        expect(response).to redirect_to("/browser_extensions")
      end
    end
  end
end
