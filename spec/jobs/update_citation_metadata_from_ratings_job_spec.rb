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
          keywords: ["debt ceiling", "joe biden", "kevin mccarthy", "textaboveleftsmallwithrule", "the political scene", "u.s. budget", "u.s. congress", "u.s. presidents", "web"],
          word_count: 2_040
        }
      end
      it "parses" do
        expect(citation.url).to eq submitted_url.gsub("?utm_s=example", "")
        expect(publisher.reload.name).to eq "newyorker"
        expect(publisher.name_assigned?).to be_falsey
        expect(publisher.base_word_count).to eq 100
        expect(rating.metadata_at).to be_within(1).of Time.current
        expect(rating.citation_metadata_raw.count).to eq 33
        expect_hashes_to_match(MetadataAttributer.from_rating(rating).except(:published_updated_at), metadata_attrs.except(:published_updated_at), match_time_within: 1)
        instance.perform(citation.id)
        citation.reload
        expect_attrs_to_match_hash(citation, metadata_attrs.except(:keywords))
        # Updates publisher
        expect(publisher.reload.name).to eq "The New Yorker"
        expect(publisher.name_assigned?).to be_truthy
      end
      context "topics present" do
        let!(:topic1) { Topic.find_or_create_for_name("U.S. President") }
        let!(:topic2) { Topic.find_or_create_for_name("Joe Biden", parents_string: "U.S. presidents") }
        let(:metadata_with_topics) { metadata_attrs.merge(topics_string: "Joe Biden") }
        it "assigns topics" do
          expect(topic1.reload.children.pluck(:id)).to eq([topic2.id])
          expect_hashes_to_match(MetadataAttributer.from_rating(rating).except(:published_updated_at), metadata_with_topics.except(:published_updated_at), match_time_within: 1)
          instance.perform(citation.id)
          citation.reload
          expect_attrs_to_match_hash(citation, metadata_with_topics.except(:keywords))
        end
      end
      context "already assigned" do
        let(:initial_attrs) { {authors: "z", published_at: Time.current, description: "c", word_count: 33, published_updated_at: Time.current, paywall: true} }
        it "updates" do
          citation.update(initial_attrs)
          publisher.update(name: "Cool publisher")
          instance.perform(citation.id)
          citation.reload
          # TODO: better handle on paywall!
          expect_attrs_to_match_hash(citation, metadata_attrs.except(:publisher_name, :paywall, :keywords))
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
            keywords: [],
            topics_string: nil,
            word_count: 186
          }
        end
        it "parses but is overridden" do
          expect(rating.citation_id).to eq rating_older.citation_id
          rating_older.update(metadata_at: Time.current - 4.hours)
          # Process the ratings
          rating.set_metadata_attributes!
          rating_older.set_metadata_attributes!
          expect_hashes_to_match(rating_older.reload.metadata_attributes, target_older, match_time_within: 1)

          instance.perform(citation.id)
          citation.reload
          expect_attrs_to_match_hash(citation, metadata_attrs.except(:published_updated_at, :keywords))
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
          keywords: ["NRPLUS Member Articles", "Nuclear Power", "Premium Content", "section: Article", "topic: Capital Matters", "topic: Energy & Environment", "topic: The Economy"],
          topics_string: nil,
          word_count: 9_949
        }
      end
      it "parses" do
        expect_hashes_to_match(MetadataAttributer.from_rating(rating), metadata_attrs, match_time_within: 1)
        # This is an erroneous published at date!
        expect(metadata_attrs[:published_at]).to be > metadata_attrs[:published_updated_at]
        instance.perform(citation.id)
        expect_hashes_to_match(rating.reload.metadata_attributes, metadata_attrs, match_time_within: 1)
        citation.reload
        expect_attrs_to_match_hash(citation, metadata_attrs.merge(published_updated_at: nil).except(:keywords), match_time_within: 1)
        # Updates publisher
        expect(publisher.reload.name).to eq "National Review"
        expect(publisher.name_assigned?).to be_truthy
      end
    end
  end

  describe "ordered_ratings" do
    let(:metadata_str) { '[{"name":"author","content":"Cool person"}]' }
    let!(:rating1) { FactoryBot.create(:rating, source: "safari_extension-0.8.1", citation_metadata_str: metadata_str) }
    let(:url) { rating1.submitted_url }
    let!(:rating2) { FactoryBot.create(:rating, submitted_url: url, source: "safari_extension-0.7.0", citation_metadata_str: metadata_str) }
    let!(:rating3) { FactoryBot.create(:rating, submitted_url: url, source: "safari_extension-0.8.1", citation_metadata_str: metadata_str) }
    let!(:rating4) { FactoryBot.create(:rating, submitted_url: url, source: "safari_extension-0.9.0") }
    let(:citation) { rating1.citation }
    it "returns in expected order" do
      rating1.update_column :metadata_at, Time.current - 2.days
      rating3.update_column :metadata_at, Time.current - 3.days
      expect(rating2.reload.metadata_at).to be_within(5).of Time.current
      expect(citation.reload.ratings.pluck(:id)).to match_array([rating1.id, rating2.id, rating3.id, rating4.id])
      expect(described_class.ordered_ratings(citation).pluck(:id)).to eq([rating1.id, rating3.id, rating2.id])
    end
  end
end
