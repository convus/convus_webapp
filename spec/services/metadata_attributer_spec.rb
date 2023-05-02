require "rails_helper"

RSpec.describe MetadataAttributer do
  let(:subject) { described_class }
  describe "from_rating" do
    let(:rating) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: citation_metadata_str) }
    context "new yorker" do
      let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_new_yorker.json")) }
      let(:submitted_url) { "https://www.newyorker.com/news/the-political-scene/the-risky-gamble-of-kevin-mccarthys-debt-ceiling-strategy?utm_s=example" }
      let(:metadata_attrs) do
        {
          authors: ["Jonathan Blitzer"],
          published_at: Time.at(1682713348),
          published_updated_at: Time.at(1682713348),
          description: "Jonathan Blitzer writes about the House Republican’s budget proposal that was bundled with its vote to raise the debt ceiling, and about Kevin McCarthy’s weakened position as Speaker.",
          canonical_url: nil,
          word_count: 2_037,
          paywall: false,
          publisher_name: "The New Yorker"
        }
      end
      it "returns target" do
        json_ld = subject.json_ld_hash(rating.citation_metadata)

        expect(subject.metadata_authors(rating.citation_metadata, json_ld)).to eq(["Jonathan Blitzer"])
        expect(subject.metadata_published_at(rating.citation_metadata, json_ld)&.to_i).to be_within(1).of 1682713348
        expect(subject.metadata_published_updated_at(rating.citation_metadata, json_ld)&.to_i).to be_within(1).of 1682713348
        expect(subject.metadata_description(rating.citation_metadata, json_ld)).to eq "Jonathan Blitzer writes about the House Republican’s budget proposal that was bundled with its vote to raise the debt ceiling, and about Kevin McCarthy’s weakened position as Speaker."
        expect(subject.metadata_canonical_url(rating.citation_metadata, json_ld)).to be_nil
        expect(subject.metadata_word_count(rating.citation_metadata, json_ld, 100)).to eq 2_037
        expect(subject.metadata_paywall(rating.citation_metadata, json_ld)).to be_falsey
        expect_hashes_to_match(subject.from_rating(rating), metadata_attrs, match_time_within: 1)
      end
    end
  end

  describe "json_ld" do
    let(:rating_metadata) { [{"json_ld" => values}] }
    let(:values) { [{"url" => "https://www.example.com"}] }
    it "returns json_ld" do
      expect(subject.json_ld_hash(rating_metadata)).to eq(values.first)
    end
    context "multiple json_ld items" do
      it "raises" do
        expect {
          subject.json_ld_hash(rating_metadata + rating_metadata)
        }.to raise_error(/multiple/i)
      end
    end
    context "multiple json_ld values" do
      let(:values) { [{"url" => "https://www.example.com"}, {"@type" => "OtherThing"}] }
      it "reduces" do
        expect(subject.json_ld_hash(rating_metadata)).to eq({"url" => "https://www.example.com", "@type" => "OtherThing"})
      end
    end
    context "multiple matching values" do
      let(:values) { [{"url" => "https://www.example.com"}, {"url" => "https://www.example.com"}] }
      it "raises" do
        expect {
          subject.json_ld_hash(rating_metadata + rating_metadata)
        }.to raise_error(/multiple/i)
      end
    end
    context "more dataexample" do
      let(:values) { [{"url" => "https://example.com", "@type" => "NewsArticle", "image" => {"url" => "https://example.com/image.png", "@type" => "ImageObject", "width" => 2057, "height" => 1200}, "author" => ["John Doe"], "creator" => ["John Doe"], "hasPart" => [], "@context" => "http://schema.org", "headline" => "example title", "keywords" => ["topic: Cool Matters"]}, {"@type" => "BreadcrumbList", "@context" => "https://schema.org/"}] }
      let(:target) do
        {
          "url" => "https://example.com",
          "@type" => "NewsArticle",
          "image" => {"url" => "https://example.com/image.png", "@type" => "ImageObject", "width" => 2057, "height" => 1200},
          "author" => ["John Doe"],
          "creator" => ["John Doe"],
          "hasPart" => [],
          "@context" => "http://schema.org",
          "headline" => "example title",
          "keywords" => ["topic: Cool Matters"]
        }
      end
      it "raises" do
        expect(subject.json_ld_hash(rating_metadata)).to eq target
      end
    end
  end
end
