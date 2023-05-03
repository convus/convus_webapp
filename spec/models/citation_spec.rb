require "rails_helper"

RSpec.describe Citation, type: :model do
  describe "factory" do
    let(:citation) { FactoryBot.create(:citation, title: "   ") }
    it "is valid" do
      expect(citation).to be_valid
      expect(citation.title).to be_nil
    end
  end

  describe "find_for_url" do
    let!(:citation) { Citation.find_or_create_for_url("https://example.convus.org") }
    let(:url_components) { {host: "example.convus.org", path: nil, query: nil}.with_indifferent_access }
    it "finds for matching url" do
      expect(Citation.find_for_url("https://example.convus.org/")&.id).to eq citation.id
      expect(Citation.find_for_url("http://example.convus.org#anchorrr")&.id).to eq citation.id
      expect(Citation.url_to_components("http://example.CONVUS.orG#ancho&")).to eq url_components
      expect(Citation.find_for_url("http://example.CONVUS.orG#ancho&")&.id).to eq citation.id
      # Even if the query has an empty value, it's still a separate URL
      expect(Citation.url_to_components("http://example.CONVUS.orG?something=#ancho")).to eq url_components.merge(query: {something: ""}.with_indifferent_access)
      expect(Citation.find_for_url("http://example.CONVUS.orG?something=#ancho")&.id).to be_blank
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
    describe "without www and with query" do
      let(:citation) { Citation.find_or_create_for_url("http://convus.org?here=true") }
      let(:url_components) { {host: "convus.org", path: nil, query: {here: "true"}}.with_indifferent_access }
      it "finds" do
        expect(citation).to be_valid
        expect(citation.url_components).to eq url_components
        expect(Citation.matching_url_components(url_components).first&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("convus.org?here=true")&.id).to eq citation.id
        expect(Citation.url_to_components("CONVUS.ORG/?here=true#things")).to eq url_components
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
        url2 = "https://convus.org/other/things?there=false&here=true"
        expect(Citation.url_to_components(url2)).to eq url_components
        expect(Citation.find_or_create_for_url(url2)&.id).to eq citation.id
        url3 = "https://convus.org/other/things?UTM_CAMPAIGN=river&there=false&utm_content=top-bar-latest&here=true"
        expect(Citation.url_to_components(url3)).to eq url_components
        expect(Citation.find_or_create_for_url(url3)&.id).to eq citation.id
        expect {
          Citation.find_or_create_for_url("https://convus.org/other/things?there=0&here=1")
        }.to change(Citation, :count).by 1
      end
    end
    describe "query array" do
      let(:citation) { Citation.find_or_create_for_url("https://convus.org/other/things?here=true&a[]=&a[]=z&a[]=f") }
      let(:url_components) { {host: "convus.org", path: "/other/things", query: {here: "true", a: ["f", "z"]}}.with_indifferent_access }
      it "finds" do
        expect(citation).to be_valid
        expect(citation.url_components).to eq url_components
        url1 = "https://convus.org/other/things?here=true&&a[]=z&a[]=f"
        expect(Citation.url_to_components(url1)).to eq url_components
        expect(Citation.find_or_create_for_url(url1)&.id).to eq citation.id
        url2 = "https://convus.org/other/things?here=true&a[]&a[]=f&a[]&a[]=z&utm_content=top-bar-latest"
        expect(Citation.url_to_components(url2)).to eq url_components
        expect(Citation.find_or_create_for_url(url2)&.id).to eq citation.id
        expect(Citation.find_or_create_for_url("https://convus.org/other/things?UTM_CAMPAIGN=river&a[]=f&a[]&a[]=z&utm_content=top-bar-latest&here=true")&.id).to eq citation.id
        expect(Citation.matching_url_components(url_components).first&.id).to eq citation.id
        expect(Citation.matching_url_components(url_components.merge(query: {here: "true"})).first&.id).to be_blank
      end
    end
    describe "youtube" do
      let(:url) { "https://www.youtube.com/watch?v=5u9s8m8uaO4" }
      let!(:citation) { Citation.find_or_create_for_url(url) }
      let(:other_url) { "https://www.youtube.com/watch?v=DkS1pkKpILY" }
      it "creates separate citations for separate videos" do
        expect(citation).to be_valid
        expect(Citation.find_for_url("#{url}&req_id=1241231234")&.id).to eq citation.id
        expect(Citation.find_for_url(other_url)).to be_blank
        # Sanity check, make sure it isn't clobbered
        expect {
          Citation.find_or_create_for_url(other_url)
        }.to change(Citation, :count).by 1
        expect(Citation.last.url).to eq other_url
        expect(citation.reload.url).to eq url
      end
    end
    describe "nytimes, remove_query" do
      let!(:publisher) { Publisher.find_or_create_for_domain("nytimes.com", remove_query: true) }
      let(:url) { "https://www.nytimes.com/interactive/2023/03/10/climate/buildings-carbon-dioxide-emissions-climate.html?action=click&algo=bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1&alpha=0.05&block=more_in_recirc&fellback=false&imp_id=375080313&impression_id=fe98acf1-c480-11ed-a679-93706db9db3a&index=1&pgtype=Article&pool=more_in_pools%2Fclimate&region=footer&req_id=201785425&surface=eos-more-in&variant=0_bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1" }
      let(:url_cleaned) { "https://www.nytimes.com/interactive/2023/03/10/climate/buildings-carbon-dioxide-emissions-climate.html?algo=bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1&alpha=0.05&block=more_in_recirc&fellback=false&imp_id=375080313&index=1&pgtype=Article&pool=more_in_pools%2Fclimate&region=footer&surface=eos-more-in&variant=0_bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1" }
      let(:url_no_query) { "https://www.nytimes.com/interactive/2023/03/10/climate/buildings-carbon-dioxide-emissions-climate.html" }
      let(:citation) { Citation.find_or_create_for_url(url) }
      it "returns target url" do
        expect(citation.reload.url).to eq url_no_query
        expect(Citation.find_for_url(url)&.id).to eq citation.id
        expect(Citation.find_for_url(url_cleaned)&.id).to eq citation.id
        expect(Citation.find_for_url(url_no_query)&.id).to eq citation.id
      end
    end

    describe "topics_string" do
      let!(:topic) { FactoryBot.create(:topic, name: "San Francisco") }
      let(:citation) { FactoryBot.create(:citation) }
      it "updates" do
        expect(citation.reload.topics.pluck(:id)).to eq([])
        citation.manually_updating = true
        citation.update(topics_string: "san francisco")
        expect(citation.reload.topics.pluck(:id)).to eq([topic.id])
        expect(citation.topics_string).to eq "San Francisco"
        expect(citation.manually_updated_attributes).to eq(["topics"])
        citation.manually_updating = false
        citation.update(topics_string: "")
        expect(citation.reload.topics_string).to be_blank
        expect(citation.manually_updated_attributes).to eq([])
      end
      context "multiple, manually_updating" do
        let!(:topic2) { FactoryBot.create(:topic, name: "Housing") }
        it "updates" do
          expect(citation.reload.topics.pluck(:id)).to eq([])
          citation.update(topics_string: "san francisco, housing")
          expect(citation.reload.topics_string).to eq "Housing, San Francisco"
          expect(citation.manually_updated_attributes).to eq([])
          expect(citation.topics.pluck(:id).sort).to eq([topic.id, topic2.id])
          citation.update(manually_updating: true, topics_string: "SAN francisco, HOUSING, housing")
          expect(citation.reload.topics_string).to eq "Housing, San Francisco"
          expect(citation.manually_updated_attributes).to eq([])
          citation.update(manually_updating: true, topics_string: "SAN francisco")
          expect(citation.reload.topics_string).to eq "San Francisco"
          expect(citation.manually_updated_attributes).to eq(["topics"])
          citation.update(manually_updating: false, topics_string: "")
          expect(citation.reload.topics_string).to eq ""
          expect(citation.manually_updated_attributes).to eq([])
        end
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

  describe "manually updated" do
    let(:citation) { FactoryBot.create(:citation) }
    it "assigns when manual_update" do
      citation.update(title: "ffff")
      expect(citation.title).to eq "ffff"
      expect(citation.manually_updated_attributes).to eq([])
      citation.update(manually_updating: true, authors: ["zzzz"], title: "ffff")
      expect(citation.reload.authors).to eq(["zzzz"])
      expect(citation.manually_updated_attributes).to eq(["authors"])
      citation.manually_updating = false
      # Assigning it to blank removes it from manually_updated_attributes
      citation.update(authors: "", title: "cccc")
      expect(citation.reload.authors).to eq([])
      expect(citation.manually_updated_attributes).to eq([])
    end
  end

  describe "references_filepath" do
    let(:url) { "https://www.youtube.com/watch?v=5u9s8m8uaO4" }
    let!(:citation) { Citation.find_or_create_for_url(url) }
    let(:target) { "youtube-com/watch-v-5u9s8m8uao4" }
    it "returns target" do
      expect(citation.references_filepath).to eq target
      expect(Citation.references_filepath(url)).to eq target
    end
    context "subdomain" do
      let(:url) { "korystamper.wordpress.com/2016/03/05/its-complicated-national-grammar-day-and-apostrophe-abuse" }
      let(:target) { "korystamper-wordpress-com/2016-03-05-its-complicated-national-grammar-day-and-apostrophe-abuse" }
      it "returns target" do
        expect(citation.references_filepath).to eq target
        expect(Citation.references_filepath(url)).to eq target
      end
    end
  end
end
