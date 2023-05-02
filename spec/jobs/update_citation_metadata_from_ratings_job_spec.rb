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
          paywall: false,
          publisher_name: "The New Yorker"
        }
      end
      it "parses" do
        expect(citation.url).to eq submitted_url.gsub("?utm_s=example", "")
        expect(publisher.reload.name).to eq "newyorker"
        expect(publisher.name_assigned?).to be_falsey
        expect(publisher.base_word_count).to eq 100
        expect(rating.metadata_at).to be_within(1).of Time.current
        expect(rating.citation_metadata.count).to eq 33
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
          expect_attrs_to_match_hash(citation, metadata_attrs.except(:published_updated_at, :paywall, :publisher_name))
          # even with override, it doesn't update publisher name
          expect(publisher.reload.name).to eq "Cool publisher"
        end
      end
      context "earlier metadata" do
        let(:older_string) { '[{"content":"New Yorked","property":"og:site_name"},{"name":"author","content":"Condé Nast"},{"content":"2023-01-28T20:22:28.267Z","property":"article:published_time"},{"content":"2023-02-28T20:22:28.267Z","property":"article:modified_time"},{"content":"Earlier.","property":"twitter:description"},{"word_count":286}]' }
        let(:rating_older) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: older_string) }
        let(:target_older) do
          {
            authors: ["Condé Nast"],
            published_at: Time.at(1674937348),
            published_updated_at: Time.at(1677615748),
            description: "Earlier.",
            canonical_url: nil,
            paywall: false,
            publisher_name: "New Yorked",
            word_count: 186
          }
        end
        it "parses but is overridden" do
          expect(rating.citation_id).to eq rating_older.citation_id
          rating_older.update(metadata_at: Time.current - 4.hours)
          expect_hashes_to_match(rating_older.citation_metadata_attributes, target_older, match_time_within: 1)
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
          published_updated_at: Time.at(1600246002),
          description: "Last week’s groundbreaking approval of the first-ever commercial small modular reactor in the United States fits a wider trend of private-sector leadership on nuclear innovation. We should strive to harness this further, and to remain optimistic about the future of nuclear energy in America.",
          canonical_url: nil,
          paywall: true,
          publisher_name: "National Review",
          word_count: 9_949
        }
      end
      it "parses" do
        expect_hashes_to_match(rating.citation_metadata_attributes, metadata_attrs, match_time_within: 1)
        # This is an erroneous published at date!
        expect(metadata_attrs[:published_at]).to be > metadata_attrs[:published_updated_at]
        instance.perform(citation.id)
        citation.reload
        expect_attrs_to_match_hash(citation, metadata_attrs.merge(published_updated_at: nil), match_time_within: 1)
        # Updates publisher
        expect(publisher.reload.name).to eq "National Review"
        expect(publisher.name_assigned?).to be_truthy
      end
    end
  end
end