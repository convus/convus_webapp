# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateCitationMetadataFromRatingsJob, type: :job do
  let(:instance) { described_class.new }
  let(:rating) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: citation_metadata_str) }
  let(:citation) { rating.citation }
  let(:publisher) { citation.publisher }

  describe "perform" do
    context "nil" do
      let(:citation_metadata_str) { "{}" }
      let(:submitted_url) { "https://www.newyorker.com/news/the-political-scene/the-risky-gamble-of-kevin-mccarthys-debt-ceiling-strategy" }
      it "doesn't error" do
        expect(rating).to be_valid
        expect(citation).to be_valid
        instance.perform(citation.id)
        citation.reload
      end
    end
    context "new yorker" do
      let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_new_yorker.json")) }
      let(:submitted_url) { "https://www.newyorker.com/news/the-political-scene/the-risky-gamble-of-kevin-mccarthys-debt-ceiling-strategy?utm_s=example" }
      let(:metadata_attrs) do
        {
          authors: ["Jonathan Blitzer"],
          published_at: Time.at(1682713348),
          published_updated_at: nil,
          description: "Jonathan Blitzer writes about the House Republican’s budget proposal that was bundled with its vote to raise the debt ceiling, and about Kevin McCarthy’s weakened position as Speaker.",
          canonical_url: "https://www.newyorker.com/news/the-political-scene/the-risky-gamble-of-kevin-mccarthys-debt-ceiling-strategy",
          paywall: false,
          publisher_name: "The New Yorker",
          title: "The Risky Gamble of Kevin McCarthy’s Debt-Ceiling Strategy",
          topic_names: ["debt ceiling", "joe biden", "kevin mccarthy", "textaboveleftsmallwithrule", "the political scene", "u.s. budget", "u.s. congress", "web"],
          word_count: 2_040
        }
      end
      it "parses" do
        expect(citation.url).to eq submitted_url.gsub("?utm_s=example", "")
        expect(publisher.reload.name).to eq "newyorker"
        expect(publisher.name_assigned?).to be_falsey
        expect(publisher.base_word_count).to eq 100
        expect(rating.metadata_at).to be_within(1).of Time.current
        expect(rating.citation_metadata.count).to eq 33
        expect_hashes_to_match(MetadataAttributer.from_rating(rating).except(:published_updated_at), metadata_attrs.except(:published_updated_at), match_time_within: 1)
        instance.perform(citation.id)
        citation.reload
        expect_attrs_to_match_hash(citation, metadata_attrs.except(:topic_names))
        # Updates publisher
        expect(publisher.reload.name).to eq "The New Yorker"
        expect(publisher.name_assigned?).to be_truthy
      end
      context "already assigned" do
        let(:initial_attrs) { {authors: "z", published_at: Time.current, description: "c", word_count: 33, published_updated_at: Time.current, paywall: true} }
        it "updates" do
          citation.update(initial_attrs)
          publisher.update(name: "Cool publisher")
          instance.perform(citation.id)
          citation.reload
          # TODO: better handle on paywall!
          expect_attrs_to_match_hash(citation, metadata_attrs.except(:publisher_name, :paywall, :topic_names))
          # It doesn't re-update the publisher
          expect(publisher.reload.name).to eq "Cool publisher"
        end
        context "manually_updated" do
          it "doesn't update" do
            citation.manually_updating = true
            citation.update(initial_attrs)
            expect(citation.reload.manually_updated_attributes).to eq(%w[authors description paywall published_at published_updated_at word_count])
            publisher.update(name: "Cool publisher")
            instance.perform(citation.id)
            citation.reload
            expect_attrs_to_match_hash(citation, initial_attrs)
            # It doesn't re-update the publisher
            expect(publisher.reload.name).to eq "Cool publisher"
          end
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
            topic_names: [],
            word_count: 186
          }
        end
        it "parses but is overridden" do
          expect(rating.citation_id).to eq rating_older.citation_id
          rating_older.update(metadata_at: Time.current - 4.hours)
          expect_hashes_to_match(rating_older.citation_metadata_attributes, target_older, match_time_within: 1)
          instance.perform(citation.id)
          citation.reload
          expect_attrs_to_match_hash(citation, metadata_attrs.except(:published_updated_at, :topic_names))
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
          canonical_url: "https://www.nationalreview.com/2020/09/nuclear-energy-private-sector-shaping-future-of-industry/",
          paywall: true,
          publisher_name: "National Review",
          title: "How the Private Sector Is Shaping the Future of Nuclear Energy",
          topic_names: ["NRPLUS Member Articles", "Nuclear Power", "Premium Content", "section: Article", "topic: Capital Matters", "topic: Energy & Environment", "topic: The Economy"],
          word_count: 9_949
        }
      end
      it "parses" do
        expect_hashes_to_match(MetadataAttributer.from_rating(rating), metadata_attrs, match_time_within: 1)
        expect_hashes_to_match(rating.citation_metadata_attributes, metadata_attrs, match_time_within: 1)
        # This is an erroneous published at date!
        expect(metadata_attrs[:published_at]).to be > metadata_attrs[:published_updated_at]
        instance.perform(citation.id)
        citation.reload
        expect_attrs_to_match_hash(citation, metadata_attrs.merge(published_updated_at: nil).except(:topic_names), match_time_within: 1)
        # Updates publisher
        expect(publisher.reload.name).to eq "National Review"
        expect(publisher.name_assigned?).to be_truthy
      end
    end
  end
end
