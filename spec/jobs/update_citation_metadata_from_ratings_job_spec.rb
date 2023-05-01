# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateCitationMetadataFromRatingsJob, type: :job do
  let(:instance) { described_class.new }
  let(:rating) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: citation_metadata_str) }
  let(:citation) { rating.citation }
  let(:publisher) { citation.publisher }

  describe "perform" do
    context "new yorker" do
      let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_new_yorker.json")) }
      let(:submitted_url) { "https://www.newyorker.com/news/the-political-scene/the-risky-gamble-of-kevin-mccarthys-debt-ceiling-strategy?utm_s=example" }
      let(:metadata_attrs) do
        {
          authors: ["Jonathan Blitzer"],
          published_at: Time.at(1682713348),
          published_updated_at: nil,
          description: "Jonathan Blitzer writes about the House Republican’s budget proposal that was bundled with its vote to raise the debt ceiling, and about Kevin McCarthy’s weakened position as Speaker.",
          canonical_url: nil,
          word_count: 2_037,
          paywall: false
        }
      end
      it "parses" do
        expect(citation.url).to eq submitted_url.gsub("?utm_s=example", "")
        expect(publisher.reload.name).to eq "newyorker"
        expect(publisher.name_assigned?).to be_falsey
        expect(publisher.base_word_count).to eq 100
        expect(rating.metadata_at).to be_within(1).of Time.current
        expect(rating.citation_metadata.count).to eq 33
        expect(instance.metadata_authors(rating.citation_metadata)).to eq(["Jonathan Blitzer"])
        expect(instance.metadata_published_at(rating.citation_metadata)&.to_i).to be_within(1).of 1682713348
        expect(instance.metadata_published_updated_at(rating.citation_metadata)&.to_i).to be_within(1).of 1682713348
        expect(instance.metadata_description(rating.citation_metadata)).to eq "Jonathan Blitzer writes about the House Republican’s budget proposal that was bundled with its vote to raise the debt ceiling, and about Kevin McCarthy’s weakened position as Speaker."
        expect(instance.metadata_canonical_url(rating.citation_metadata)).to be_nil
        expect(instance.metadata_word_count(rating.citation_metadata)).to eq 2_037
        expect(instance.metadata_paywall(rating.citation_metadata)).to be_falsey
        instance.perform(citation.id)
        citation.reload
        expect_attrs_to_match_hash(citation, metadata_attrs)
        # Updates publisher
        expect(publisher.reload.name).to eq "The New Yorker"
        expect(publisher.name_assigned?).to be_truthy
      end
      context "already assigned" do
        it "updates only if override" do
          initial_attrs = {authors: "z", published_at: Time.current, description: "c", word_count: 33, published_updated_at: Time.current, paywall: true}
          citation.update(initial_attrs)
          publisher.update(name: "Cool publisher")
          instance.perform(citation.id)
          citation.reload
          expect_attrs_to_match_hash(citation, initial_attrs)
          # And then, with override
          instance.perform(citation.id, true)
          citation.reload
          expect_attrs_to_match_hash(citation, metadata_attrs.except(:published_updated_at, :paywall))
          # even with override, it doesn't update publisher name
          expect(publisher.reload.name).to eq "Cool publisher"
        end
      end
      context "earlier metadata" do
        let(:older_string) { '[{"content":"New Yorked","property":"og:site_name"},{"name":"author","content":"Condé Nast"},{"content":"2023-01-28T20:22:28.267Z","property":"article:published_time"},{"content":"2023-02-28T20:22:28.267Z","property":"article:modified_time"},{"content":"Earlier.","property":"twitter:description"},{"word_count":286}]' }
        let(:rating_older) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: older_string) }
        it "parses but is overridden" do
          expect(rating.citation_id).to eq rating_older.citation_id
          rating_older.update(metadata_at: Time.current - 4.hours)
          expect(instance.metadata_authors(rating_older.citation_metadata)).to eq(["Condé Nast"])
          expect(instance.metadata_published_at(rating_older.citation_metadata)&.to_i).to be_within(1).of 1674937348
          expect(instance.metadata_published_updated_at(rating_older.citation_metadata)&.to_i).to be_within(1).of 1677615748
          expect(instance.metadata_description(rating_older.citation_metadata)).to eq "Earlier."
          expect(instance.metadata_canonical_url(rating_older.citation_metadata)).to be_nil
          # expect(instance.metadata_word_count(rating_older.citation_metadata)).to eq 286 # Lazy ivar useage
          expect(instance.metadata_paywall(rating_older.citation_metadata)).to be_falsey
          instance.perform(citation.id)
          citation.reload
          expect_attrs_to_match_hash(citation, metadata_attrs.except(:published_updated_at))
        end
      end
    end
    context "national review" do
      let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_national_review.json")) }
      let(:submitted_url) { "https://www.nationalreview.com/2020/09/nuclear-energy-private-sector-shaping-future-of-industry/" }
      let(:metadata_attrs) do
        {
          authors: ["Christopher Barnard"],
          published_at: Time.at(1600252259),
          published_updated_at: nil,
          description: "Last week’s groundbreaking approval of the first-ever commercial small modular reactor in the United States fits a wider trend of private-sector leadership on nuclear innovation. We should strive to harness this further, and to remain optimistic about the future of nuclear energy in America.",
          canonical_url: nil,
          word_count: 9_949,
          paywall: true
        }
      end
      it "parses" do
        instance.perform(citation.id)
        citation.reload
        expect_attrs_to_match_hash(citation, metadata_attrs)
        # Updates publisher
        expect(publisher.reload.name).to eq "National Review"
        expect(publisher.name_assigned?).to be_truthy
      end
    end
  end

  describe "json_ld" do
    let(:rating_metadata) { [{"json_ld" => values}] }
    let(:values) { [{"url"=> "https://www.example.com"}] }
    it "returns json_ld" do
      expect(instance.json_ld(rating_metadata)).to eq(values.first)
    end
    context "multiple json_ld items" do
      it "raises" do
        expect {
          instance.json_ld(rating_metadata + rating_metadata)
        }.to raise_error(/multiple/i)
      end
    end
    context "multiple json_ld values" do
      let(:values) { [{"url"=> "https://www.example.com"}, {"@type" => "OtherThing"}] }
      it "reduces" do
        expect(instance.json_ld(rating_metadata)).to eq({"url"=> "https://www.example.com", "@type" => "OtherThing"})
      end
    end
    context "multiple matching values" do
      let(:values) { [{"url"=> "https://www.example.com"}, {"url"=> "https://www.example.com"}] }
      it "raises" do
        expect {
          instance.json_ld(rating_metadata + rating_metadata)
        }.to raise_error(/multiple/i)
      end
    end
    context "more dataexample" do
      let(:values) { [{"url"=>"https://example.com","@type"=>"NewsArticle","image"=>{"url"=>"https://example.com/image.png","@type"=>"ImageObject","width"=>2057,"height"=>1200},"author"=>["John Doe"],"creator"=>["John Doe"],"hasPart"=>[],"@context"=>"http://schema.org","headline"=>"example title","keywords"=>["topic: Cool Matters"]},{"@type"=> "BreadcrumbList","@context"=> "https://schema.org/"}] }
      let(:target) do
        {
          "url"=>"https://example.com",
          "@type"=>"NewsArticle",
          "image"=>{"url"=>"https://example.com/image.png","@type"=>"ImageObject","width"=>2057,"height"=>1200},
          "author"=>["John Doe"],
          "creator"=>["John Doe"],
          "hasPart"=>[],
          "@context"=>"http://schema.org",
          "headline"=>"example title",
          "keywords"=>["topic: Cool Matters"]
        }
      end
      it "raises" do
        expect(instance.json_ld(rating_metadata)).to eq target
      end
    end
  end
end
