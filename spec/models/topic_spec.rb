require "rails_helper"

RSpec.describe Topic, type: :model do
  describe "factory" do
    let(:topic) { FactoryBot.create(:topic) }
    it "is valid" do
      expect(topic).to be_valid
      expect(topic.orphaned).to be_truthy
      expect(topic.send(:calculated_orphaned?)).to be_truthy
    end
    context "with review_topic" do
      let(:review_topic) { FactoryBot.create(:review_topic, topic: topic) }
      it "is not orphaned" do
        expect(review_topic).to be_valid
        expect(topic.send(:calculated_orphaned?)).to be_falsey
        expect(topic.orphaned).to be_truthy
        topic.update(updated_at: Time.current)
        expect(topic.reload.orphaned).to be_falsey
      end
    end
    context "with citation_topic" do
      let(:citation_topic) { FactoryBot.create(:citation_topic, topic: topic) }
      let(:review) { FactoryBot.create(:review, submitted_url: citation_topic.citation.url) }
      let(:review_topic) { FactoryBot.create(:review_topic, review: review, topic: topic) }
      it "is not orphaned" do
        expect(citation_topic).to be_valid
        expect(topic.send(:calculated_orphaned?)).to be_truthy
        expect(topic.orphaned).to be_truthy
        topic.update(updated_at: Time.current)
        expect(topic.reload.orphaned).to be_truthy
        expect(citation_topic.orphaned).to be_truthy
        # With review_topic nothing is orphaned
        expect(review_topic.citation&.id).to eq citation_topic.citation_id
        expect(topic.send(:calculated_orphaned?)).to be_falsey
        expect(citation_topic.send(:calculated_orphaned?)).to be_falsey
        topic.update(updated_at: Time.current)
        citation_topic.update(updated_at: Time.current)
        expect(topic.reload.orphaned).to be_falsey
        expect(citation_topic.orphaned).to be_falsey
      end
    end
    context "numbers only" do
      let(:topic) { FactoryBot.build(:topic, name: "111") }
      it "is invalid" do
        expect(topic).to be_invalid
        expect(topic.errors.full_messages).to eq(["Name can't be only numbers"])
      end
    end
  end

  describe "unique by name" do
    let(:topic) { FactoryBot.create(:topic, name: "First topic we have") }
    let(:topic_dupe) { FactoryBot.build(:topic, name: name) }
    let(:name) { topic.name }
    it "sets the slug, validates by slug" do
      expect(topic).to be_valid
      expect(topic.slug).to eq "first-topic-we-have"
      expect(topic_dupe).to_not be_valid
      expect(topic_dupe.errors.full_messages).to eq(["Name has already been taken"])
    end
    context "slug match" do
      let(:name) { " FIRST topic we have\n" }
      it "sets the slug, validates by slug" do
        expect(topic).to be_valid
        expect(topic.slug).to eq "first-topic-we-have"
        topic_dupe.save
        expect(topic_dupe.name).to_not eq topic.name
        expect(topic_dupe.errors.full_messages).to eq(["Name has already been taken"])
      end
    end
  end

  describe "find_or_create_for" do
    let!(:topic) { FactoryBot.create(:topic, name: "First topic we have") }
    it "finds the existing" do
      expect(Topic.count).to eq 1
      expect(Topic.find_or_create_for_name("first topic we have ")&.id).to eq topic.id
      expect(Topic.find_or_create_for_name("\nFIRST topic we HAVE ")&.id).to eq topic.id
      expect(Topic.find_or_create_for_name("New first topic")&.id).to_not eq topic.id
      expect(Topic.count).to eq 2
    end
  end

  describe "matching_topics" do
    let!(:topic) { FactoryBot.create(:topic, name: "Warmth") }
    let(:review) { FactoryBot.create(:review, topics_text: "warmth") }
    let(:review2) { FactoryBot.create(:review, topics_text: "warmed") }
    before { [review.id, review2.id].each { |i| ReconcileReviewTopicsJob.new.perform(i) } }
    it "finds the things" do
      expect(review.reload.topics.pluck(:id)).to eq([topic.id])
      expect(review2.topics.count).to eq 1
      expect(Review.matching_topics(topic.id).pluck(:id)).to eq([review.id])
      # expect(Review.matching_topics([topic_id])).to eq([review.id])
    end
  end
end
