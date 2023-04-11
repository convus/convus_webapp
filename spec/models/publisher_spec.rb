require 'rails_helper'

RSpec.describe Publisher, type: :model do
  describe "factory" do
    let(:publisher) { FactoryBot.create(:publisher) }
    it "is valid" do
      expect(publisher).to be_valid
    end
  end

  describe "find_or_create_for_domain" do
    let(:publisher) { Publisher.find_or_create_for_domain("theguardian.com") }
    it "finds and creates" do
      expect(publisher).to be_valid
      expect(publisher.name).to eq "theguardian"
      expect(publisher.remove_query).to be_falsey
      # It ignores passed name if there is a match
      expect(Publisher.find_or_create_for_domain("theguardian.com", name: "BBB")&.id).to eq publisher.id
      expect(publisher.reload.name).to eq "theguardian"
    end
    context "passed name initially" do
      let(:publisher) { Publisher.find_or_create_for_domain("TheGuardian.com", name: "The Guardian", remove_query: true) }
      it "sets name if passed initially" do
        expect(publisher).to be_valid
        expect(publisher.domain).to eq "theguardian.com" # Downcased
        expect(publisher.name).to eq "The Guardian"
        expect(publisher.remove_query).to be_truthy
        expect(Publisher.find_or_create_for_domain("theguardian.com")&.id).to eq publisher.id
        expect(publisher.reload.name).to eq "The Guardian"
        expect(publisher.remove_query).to be_truthy
      end
    end
    context "subdomain" do
      let(:publisher) { Publisher.find_or_create_for_domain("epistemink.substack.com") }
      it "name doesn't remove subdomain" do
        expect(publisher).to be_valid
        expect(publisher.name).to eq "epistemink.substack"
        expect(publisher.remove_query).to be_falsey
      end
    end
  end

  describe "on create of citation" do
    let(:url) { "https://www.politico.com/story/2019/07/15/poll-dc-statehood-1415882?k=v" }
    let(:citation) { FactoryBot.create(:citation, url: url) }
    it "creates" do
      publisher = citation.reload.publisher
      expect(publisher.domain).to eq "politico.com"
      expect(publisher.name).to eq "politico"
      expect(publisher.remove_query).to be_falsey
    end
    context "publisher exists" do
      let!(:publisher) { Publisher.find_or_create_for_domain("politico.com") }
      it "associates" do
        expect(publisher.domain).to eq "politico.com"
        expect(publisher.name).to eq "politico"
        expect(publisher.remove_query).to be_falsey
        expect(citation.reload.publisher_id).to eq publisher.id
        expect(citation.url).to eq url
      end
      context "publisher remove_query" do
        let!(:publisher) { Publisher.find_or_create_for_domain("politico.com", remove_query: true) }
        it "associates and ignores query" do
          expect(publisher.domain).to eq "politico.com"
          expect(publisher.name).to eq "politico"
          expect(publisher.remove_query).to be_truthy
          expect(citation.reload.publisher_id).to eq publisher.id
          expect(citation.url).to eq url.gsub("?k=v", "")
        end
      end
    end
  end

  describe "after commit" do
    let(:url) { "https://www.csmonitor.com/Daily/2023/20230309?cmpid=ema:ddp:20230309:177:read&sfmc_sub=47630&id=115" }
    let(:url_no_query) { "https://www.csmonitor.com/Daily/2023/20230309" }
    let(:citation) { Citation.find_or_create_for_url(url) }
    let(:publisher) { citation.publisher }
    let(:url_components) do
      {
        host: "csmonitor.com", path: "/daily/2023/20230309",
        query: {cmpid: "ema:ddp:20230309:177:read", sfmc_sub: "47630", id: "115"}
      }.with_indifferent_access
    end
    it "updates all the citations if remove_query enabled" do
      expect(citation.reload.url).to eq url
      expect(citation.url_components).to eq url_components
      expect(Citation.find_for_url(url_no_query)&.id).to be_blank
      expect(publisher.remove_query).to be_falsey
      publisher.update(remove_query: true)
      expect(citation.reload.url).to eq url_no_query
      expect(citation.url_components).to eq(url_components)
      expect(Citation.find_for_url(url_no_query)&.id).to eq citation.id
      expect(Citation.find_for_url(url)&.id).to eq citation.id
      expect(Citation.matching_url_components(url_components).first&.id).to eq citation.id
    end
  end
end
