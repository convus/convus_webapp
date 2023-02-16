require "rails_helper"

RSpec.describe Citation, type: :model do
  describe "factory" do
    let(:citation) { FactoryBot.create(:citation, title: "   ") }
    it "is valid" do
      expect(citation).to be_valid
      expect(citation.title).to be_nil
    end
  end
  describe "find_or_create_for_url" do
    let(:url_components) { {host: "example.convus.org", path: nil, query: nil} }
    it "creates then finds" do
      citation = Citation.find_or_create_for_url("https://example.convus.org")
      expect(citation).to be_valid
      expect(Citation.url_to_components("https://example.convus.org")).to eq url_components
      expect(Citation.url_to_components("https://example.convus.ORG//")).to eq url_components
      expect(Citation.find_or_create_for_url("https://example.convus.org/")&.id).to eq citation.id
      expect(Citation.find_or_create_for_url("http://example.convus.org#anchorrr")&.id).to eq citation.id
      expect(Citation.find_or_create_for_url("http://example.CONVUS.orG#ancho&")&.id).to eq citation.id
      expect {
        Citation.find_or_create_for_url("http://example.CONVUS.orG/ff#ancho")
      }.to change(Citation, :count).by 1
    end
    describe "with www" do
      let(:citation) { Citation.find_or_create_for_url("https://www.convus.org/stuff") }
      let(:url_components) { {host: "convus.org", path: "/stuff", query: nil} }
      it "finds" do
        expect(citation).to be_valid
        expect(Citation.find_or_create_for_url("convus.org/stuff")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("www.convus.org/stuff")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("http://convus.org/stuff")&.id).to eq citation.id
      end
    end
    # describe "without www" do
    #   let(:citation) { Citation.find_or_create_for_url("http://convus.org/other/things?here=true") }
    #   it "finds" do
    #     expect(citation).to be_valid
    #     expect(Citation.find_or_create_for_url("convus.org/other/things?here=true")&.id).to eq citation.id
    #     expect(Citation.find_or_create_for_url("convus.org/other/things?here=true#things")&.id).to eq citation.id
    #     expect(Citation.find_or_create_for_url("https://convus.org/other/things?here=true")&.id).to eq citation.id
    #     expect(Citation.find_or_create_for_url("https://www.convus.org/other/things?here=true")&.id).to eq citation.id
    #   end
    # end
    # describe "multiple queries" do
    #   let(:citation) { Citation.find_or_create_for_url("convus.org/other/things?here=true&there=false") }
    #   it "finds" do
    #     expect(citation).to be_valid
    #     expect(citation.url).to eq "http://convus.org/other/things?here=true&there=false"
    #     expect(Citation.find_or_create_for_url("https://convus.org/other/things?here=true&there=false")&.id).to eq citation.id
    #     expect(Citation.find_or_create_for_url("https://convus.org/other/things?here=true&there=false&utm_content=top-bar-latest")&.id).to eq citation.id
    #     expect(Citation.find_or_create_for_url("https://convus.org/other/things?there=false&here=true")&.id).to eq citation.id
    #     expect(Citation.find_or_create_for_url("https://convus.org/other/things?UTM_CAMPAIGN=riverthere=false&utm_content=top-bar-latest&here=true")&.id).to eq citation.id

    #     # equivelant by most measures - but not actually, so we're not matching them
    #     expect {
    #       Citation.find_or_create_for_url("https://convus.org/other/things?there=0&here=1")
    #     }.to change(Citation, :count).by 1
    #   end
    # end
  end
end
