require "rails_helper"

base_url = "/api/v1/auth"
RSpec.describe base_url, type: :request do
  let(:current_user) { FactoryBot.create(:user) }

  describe "not found" do
    it "returns 404" do
      get base_url, headers: {"HTTP_ORIGIN" => "*"}
      expect(response.code).to eq "404"
      expect(json_result.to_s).to match(/couldn.t find/i)
      expect(response.headers["access-control-allow-origin"]).to eq("*")
      expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
    end
  end

  describe "status" do
    it "returns 401" do
      get "#{base_url}/status", headers: {"HTTP_ORIGIN" => "*"}
      expect(response.code).to eq "401"
      expect_hashes_to_match(json_result, {message: "missing user"})
      expect(response.headers["access-control-allow-origin"]).to eq("*")
      expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
    end
    context "with invalid user in params" do
      it "returns 401s" do
        get "#{base_url}/status", params: {api_token: "--#{current_user.api_token}"},
          headers: {"HTTP_ORIGIN" => "*"}
        expect(response.code).to eq "401"
        expect_hashes_to_match(json_result, {message: "missing user"})
        expect(response.headers["access-control-allow-origin"]).to eq("*")
        expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
      end
    end
    context "with valid user in params" do
      it "returns 200" do
        get "#{base_url}/status", params: {api_token: current_user.api_token},
          headers: {"HTTP_ORIGIN" => "*"}
        expect(response.code).to eq "200"
        expect_hashes_to_match(json_result, {message: "authenticated"})
        expect(response.headers["access-control-allow-origin"]).to eq("*")
        expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
      end
    end
    context "with valid user in auth basic" do
      it "returns 200" do
        get "#{base_url}/status", headers: {
          "HTTP_ORIGIN" => "*",
          "Authorization" => "Bearer #{current_user.api_token}"
        }
        expect(response.code).to eq "200"
        expect_hashes_to_match(json_result, {message: "authenticated"})
        expect(response.headers["access-control-allow-origin"]).to eq("*")
        expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
      end
    end
  end

  describe "create" do
    it "returns api_token" do
      post base_url, headers: json_headers, params: {
        user: {email: current_user.email, password: "password--fakepassword"}
      }.to_json
      expect(response.code).to eq "200"
      expect(json_result[:review_token]).to eq current_user.api_token
    end

    context "bare user" do
      it "returns api_token" do
        post base_url, headers: json_headers, params: {
          email: current_user.email,
          password: "password--fakepassword"
        }.to_json
        expect(response.code).to eq "200"
        expect(json_result[:review_token]).to eq current_user.api_token
      end
    end

    context "invalid" do
      it "returns 401" do
        post base_url, params: {user: {
          email: current_user.email,
          password: "not-correct-password"
        }}
        expect(response.code).to eq "401"
        expect_hashes_to_match(json_result, {message: "Incorrect email or password"})
      end
    end

    context "no csrf" do
      include_context :test_csrf_token
      it "succeeds" do
        post base_url, headers: json_headers.merge("HTTP_ORIGIN" => "*"),
          params: {
            user: {email: current_user.email, password: "password--fakepassword"}
          }.to_json
        expect(response.code).to eq "200"
        expect(json_result[:review_token]).to eq current_user.api_token
        expect(response.headers["access-control-allow-origin"]).to eq("*")
        expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
      end
    end
  end
end
