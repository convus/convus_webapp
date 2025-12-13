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
      describe "esbuild_error" do
        let(:error_file_path) { RenderEsbuildErrors.file_path }
        around do |example|
          ENV["ESBUILD_ERROR_RENDERED"] = "true"
          example.run
          ENV.delete("ESBUILD_ERROR_RENDERED")
          File.delete(error_file_path) if File.exist?(error_file_path)
        end

        it "renders normally without error file" do
          get "/"
          expect(response.code).to eq "200"
          expect(response).to render_template("landing/index")
        end

        context "with esbuild_error file present" do
          before { File.write(error_file_path, "Errored\nerror here") }

          it "renders error page" do
            get "/"
            expect(response.code).to eq "200"
            expect(response.body).to match("<h1>Errored</h1>")
            expect(response.body).to match("<pre>error here</pre>")
          end
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
