require "rails_helper"

base_url = "/api/v1/citations"
RSpec.describe base_url, type: :request do
  describe "index" do
    let(:citation) { FactoryBot.create(:citation, url: "https://www.example.com/1/2/?a=b") }
    let(:target_filename) { "example-com/1-2-a-b" }
    let(:citation_result) { {id: citation.id, url: citation.url, filename: target_filename} }
    it "returns result" do
      expect(citation.references_filepath).to eq target_filename
      get base_url, headers: json_headers.merge("HTTP_ORIGIN" => "*")
      expect(json_result["data"].count).to eq 1
      expect_hashes_to_match(json_result["data"].first, citation_result)
      expect(response.code).to eq "200"
      expect(response.headers["access-control-allow-origin"]).to eq("*")
      expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
    end
  end
end
