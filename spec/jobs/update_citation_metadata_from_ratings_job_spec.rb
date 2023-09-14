# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateCitationMetadataFromRatingsJob, type: :job do
  let(:instance) { described_class.new }
  let(:rating) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: citation_metadata_str) }
  let(:citation) { rating.citation }
  let(:publisher) { citation.publisher }

  describe "perform" do
    before do
      Sidekiq::Worker.clear_all
      # Required to enqueue PromptClaudeForCitationQuizJob
      stub_const("PromptClaudeForCitationQuizJob::QUIZ_PROMPT", "something")
    end
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
          published_at: 1682713348,
          published_updated_at: nil,
          description: "Jonathan Blitzer writes about the House Republican’s budget proposal that was bundled with its vote to raise the debt ceiling, and about Kevin McCarthy’s weakened position as Speaker.",
          canonical_url: nil,
          paywall: false,
          publisher_name: "The New Yorker",
          title: "The Risky Gamble of Kevin McCarthy’s Debt-Ceiling Strategy",
          keywords: ["debt ceiling", "joe biden", "kevin mccarthy", "textaboveleftsmallwithrule", "the political scene", "u.s. budget", "u.s. congress", "u.s. presidents", "web"],
          word_count: 2_040
        }
      end
      it "parses" do
        expect(citation.url).to eq submitted_url.gsub("?utm_s=example", "")
        expect(publisher.reload.name).to eq "newyorker.com"
        expect(publisher.name_assigned?).to be_falsey
        expect(publisher.base_word_count).to eq 100
        expect(rating.metadata_at).to be_within(1).of Time.current
        expect(rating.citation_metadata_raw.count).to eq 33
        expect_hashes_to_match(MetadataAttributer.from_rating(rating), metadata_attrs, match_time_within: 1)
        instance.perform(citation.id)
        citation.reload
        expect_attrs_to_match_hash(citation, metadata_attrs.except(:keywords))
        # Updates publisher
        expect(publisher.reload.name).to eq "The New Yorker"
        expect(publisher.name_assigned?).to be_truthy
        expect(PromptClaudeForCitationQuizJob.jobs.count).to eq 0
      end
      context "topics present" do
        let!(:topic1) { Topic.find_or_create_for_name("U.S. President") }
        let!(:topic2) { Topic.find_or_create_for_name("Joe Biden", parents_string: "U.S. presidents") }
        let!(:topic3) { Topic.find_or_create_for_name("Party") }
        let(:metadata_with_topics) { metadata_attrs.merge(topics_string: "Joe Biden") }
        let(:quiz) { FactoryBot.create(:quiz, citation: citation) }
        it "assigns topics" do
          expect(quiz.reload.subject).to be_blank
          expect(topic1.reload.children.pluck(:id)).to eq([topic2.id])
          expect_hashes_to_match(MetadataAttributer.from_rating(rating).except(:published_updated_at), metadata_with_topics.except(:published_updated_at), match_time_within: 1)
          instance.perform(citation.id)
          citation.reload
          expect_attrs_to_match_hash(citation, metadata_with_topics.except(:keywords))
          citation.update(topics_string: "\nParty\n", manually_updating: true)
          expect(citation.reload.topics.pluck(:id)).to eq([topic3.id])
          expect(citation.manually_updated_attributes).to eq(["topics"])
          instance.perform(citation.id)
          expect(citation.reload.topics.pluck(:id)).to eq([topic3.id])
          expect_attrs_to_match_hash(citation, metadata_with_topics.except(:keywords, :topics_string))
          expect(citation.reload.subject).to eq "Party"
          expect(quiz.reload.subject).to eq "Party"
          expect(quiz.subject_set_manually).to be_falsey
        end
      end
      context "citation_text present" do
        let(:citation_text) { "Some text goes here" }
        before { rating.update(citation_text: citation_text) }
        it "assigns topics and enqueues PromptClaudeForCitationQuizJob" do
          expect(PromptClaudeForCitationQuizJob.jobs.count).to eq 0
          expect(citation.citation_text).to be_nil
          instance.perform(citation.id)
          citation.reload
          expect_attrs_to_match_hash(citation, metadata_attrs.except(:keywords))
          expect(citation.citation_text).to eq citation_text
          expect(citation.manually_updated_attributes).to eq([])
          expect(PromptClaudeForCitationQuizJob.jobs.map { |j| j["args"] }.flatten).to match_array([{citation_id: citation.id}.as_json])
        end
      end
      context "already assigned" do
        let(:time) { Time.current }
        let(:initial_attrs) { {authors: "z", published_at: Time.current, description: "c", word_count: 33, published_updated_at: time, paywall: true} }
        it "updates" do
          citation.update(initial_attrs)
          publisher.update(name: "Cool publisher")
          instance.perform(citation.id)
          citation.reload
          # TODO: better handle on paywall!
          expect_attrs_to_match_hash(citation, metadata_attrs.merge(published_updated_at: time).except(:publisher_name, :paywall, :keywords))
          # It doesn't re-update the publisher
          expect(publisher.reload.name).to eq "Cool publisher"
        end
        context "manually_updated" do
          before { rating.update(citation_text: "New citation text") }
          it "doesn't update" do
            citation.manually_updating = true
            citation.update(initial_attrs.merge(citation_text: "OG Text"))
            expect(citation.reload.manually_updated_attributes).to eq(%w[authors citation_text description paywall published_at published_updated_at word_count])
            publisher.update(name: "Cool publisher")
            instance.perform(citation.id)
            citation.reload
            expect_attrs_to_match_hash(citation, initial_attrs.except(:authors))
            expect(citation.authors).to eq(["z"])
            # It doesn't re-update the publisher
            expect(publisher.reload.name).to eq "Cool publisher"
            expect(citation.citation_text).to eq "OG Text"
          end
        end
      end
      context "earlier metadata" do
        let(:older_string) { '[{"content":"New Yorked","property":"og:site_name"},{"name":"author","content":"Condé Nast"},{"content":"2023-01-28T20:22:28.267Z","property":"article:published_time"},{"content":"2023-02-28T20:22:28.267Z","property":"article:modified_time"},{"content":"Earlier.","property":"twitter:description"},{"word_count":286}]' }
        let(:rating_older) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: older_string, citation_text: "Old text") }
        let(:target_older) do
          {
            authors: ["Condé Nast"],
            published_at: 1674937348,
            published_updated_at: 1677615748,
            description: "Earlier.",
            canonical_url: nil,
            paywall: false,
            publisher_name: "New Yorked",
            keywords: [],
            topics_string: nil,
            word_count: 2
          }
        end
        before { rating.update(citation_text: "New citation text") }
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
          expect(citation.citation_text).to eq "New citation text"
        end
      end
    end
    context "national review" do
      let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_national_review.json")) }
      let(:submitted_url) { "https://www.nationalreview.com/2020/09/different-url-here" }
      let(:metadata_attrs) do
        {
          authors: ["Christopher Barnard"],
          published_at: 1600252259,
          published_updated_at: nil,
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
        # Verify it's unprocessed, and that it skips processing with skip_reprocess
        expect(rating.metadata_unprocessed?).to be_truthy
        expect(described_class.ordered_ratings(rating, skip_reprocess: true).pluck(:id)).to eq([])

        expect_hashes_to_match(MetadataAttributer.from_rating(rating), metadata_attrs, match_time_within: 1)

        instance.perform(citation.id)
        expect_hashes_to_match(rating.reload.metadata_attributes, metadata_attrs, match_time_within: 1)
        citation.reload
        expect_attrs_to_match_hash(citation, metadata_attrs.except(:keywords), match_time_within: 1)
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
