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
    let(:url_components) { {host: "example.convus.org", path: nil, query: nil}.with_indifferent_access }
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
      let(:url_components) { {host: "convus.org", path: "/stuff", query: nil}.with_indifferent_access }
      it "finds" do
        expect(citation).to be_valid
        expect(citation.url_components).to eq url_components
        expect(Citation.find_or_create_for_url("convus.org/stuff")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("www.convus.org/stuff/")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("http://convus.org/stuff")&.id).to eq citation.id
      end
    end
    describe "without www" do
      let(:citation) { Citation.find_or_create_for_url("http://convus.org?here=true") }
      let(:url_components) { {host: "convus.org", path: nil, query: {here: "true"}}.with_indifferent_access }
      it "finds" do
        expect(citation).to be_valid
        expect(citation.url_components).to eq url_components
        expect(Citation.find_or_create_for_url("convus.org?here=true")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("CONVUS.ORG/?here=true#things")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("https://convus.org/?here=true&#sttt")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("HTTPS://WWW.CONvuS.ORG/?here=true")&.id).to eq citation.id
      end
    end
    describe "multiple queries" do
      let(:citation) { Citation.find_or_create_for_url("convus.org/other/things?here=true&there=false") }
      let(:url_components) { {host: "convus.org", path: "/other/things", query: {here: "true", there: "false"}}.with_indifferent_access }
      it "finds" do
        expect(citation).to be_valid
        expect(citation.url).to eq "http://convus.org/other/things?here=true&there=false"
        expect(citation.url_components).to eq url_components
        expect(Citation.find_or_create_for_url("https://convus.org/other/things?here=true&there=false")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("https://convus.org/other/things?here=true&there=false&utm_content=top-bar-latest")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("https://convus.org/other/things?there=false&here=true")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("https://convus.org/other/things?UTM_CAMPAIGN=riverthere=false&utm_content=top-bar-latest&here=true")&.id).to eq citation.id

        # TODO: equivalent in Rails - but not actually everywhere, so this shouldn't work
        # expect {
        #   Citation.find_or_create_for_url("https://convus.org/other/things?there=0&here=1")
        # }.to change(Citation, :count).by 1
      end
    end
    describe "query array" do
      let(:citation) { Citation.find_or_create_for_url("https://convus.org/other/things?here=true&a[]=&a[]=z&a[]=f") }
      let(:url_components) { {host: "convus.org", path: "/other/things", query: {here: "true", a: ["f", "z"]}}.with_indifferent_access }
      it "finds" do
        expect(citation).to be_valid
        expect(citation.url_components).to eq url_components
        expect(Citation.find_or_create_for_url("https://convus.org/other/things?here=true&there=false&a[]=z&a[]=f")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("https://convus.org/other/things?here=true&there=false&a[]&a[]=f&a[]&a[]=z&utm_content=top-bar-latest")&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("https://convus.org/other/things?UTM_CAMPAIGN=riverthere=false&a[]=f&a[]&a[]=z&utm_content=top-bar-latest&here=true")&.id).to eq citation.id
      end
    end

    describe "topics_string" do
      let!(:topic) { FactoryBot.create(:topic, name: "San Francisco") }
      let(:citation) { FactoryBot.create(:citation) }
      it "updates" do
        expect(citation.reload.topics.pluck(:id)).to eq([])
        citation.update(topics_string: "san francisco")
        expect(citation.reload.topics.pluck(:id)).to eq([topic.id])
        expect(citation.topics_string).to eq "San Francisco"
      end
      context "build" do
        let(:citation) { FactoryBot.create(:citation, topics_string: " san francisco   ") }
        it "creates" do
          expect(citation).to be_valid
          expect(citation.reload.topics.pluck(:id)).to eq([topic.id])
          citation.update(topics_string: "   \n")
          expect(citation.reload.topics.pluck(:id)).to eq([])
          expect(citation.topics_string).to be_blank
        end
      end
    end
  end


end
