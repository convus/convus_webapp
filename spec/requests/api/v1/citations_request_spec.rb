require "rails_helper"

base_url = "/api/v1/citations"
RSpec.describe base_url, type: :request do
  describe "index" do
    let(:citation) { FactoryBot.create(:citation, url: "https://www.example.com/1/2/?a=b") }
    let(:target_filepath) { "example-com/1-2-a-b" }
    let(:citation_result) { {id: citation.id, url: citation.url, filepath: target_filepath} }
    it "returns result" do
      expect(citation.references_filepath).to eq target_filepath
      get base_url, headers: json_headers.merge("HTTP_ORIGIN" => "*")
      expect(json_result["data"].count).to eq 1
      expect_hashes_to_match(json_result["data"].first, citation_result)
      expect(response.code).to eq "200"
      expect(response.headers["access-control-allow-origin"]).to eq("*")
      expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
    end
  end

  describe "filepath" do
    let!(:publisher) { Publisher.find_or_create_for_domain("nytimes.com", remove_query: true) }
    let(:url) { "https://www.nytimes.com/interactive/2023/03/10/climate/buildings-carbon-dioxide-emissions-climate.html?algo=bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1&alpha=0.05&block=more_in_recirc&fellback=false&imp_id=375080313&index=1&pgtype=Article&pool=more_in_pools%2Fclimate&region=footer&surface=eos-more-in&variant=0_bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1" }
    let(:target) { "nytimes-com/interactive-2023-03-10-climate-buildings-carbon-dioxide-emissions-climate-html" }
    it "returns filepath" do
      expect(Citation.references_filepath(url)).to eq target
      post "#{base_url}/filepath", params: {url: url}.to_json,
        headers: json_headers.merge("HTTP_ORIGIN" => "*")
      expect(json_result).to eq({"data" => target})
      expect(response.code).to eq "200"
      expect(response.headers["access-control-allow-origin"]).to eq("*")
      expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
    end
  end
end
