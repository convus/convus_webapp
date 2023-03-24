# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReconcileRatingTopicsJob, type: :job do
  let(:instance) { described_class.new }
  let(:rating) { FactoryBot.create(:rating, topics_text: topics_text) }
  let(:topics_text) { " Some cool topic\n\n" }
  let(:citation) { rating.citation }

  describe "#perform" do
    before { Sidekiq::Worker.clear_all }
    it "creates the topics" do
      expect(Topic.count).to eq 0
      expect {
        expect(rating).to be_valid
      }.to change(described_class.jobs, :count).by(1)
      expect {
        instance.perform(rating.id)
      }.to change(described_class.jobs, :count).by(0)
      expect(Topic.count).to eq 1
      topic = Topic.last
      expect(topic.name).to eq "Some cool topic"
      expect(rating.reload.topics_text).to eq topic.name
      expect(rating.topics.pluck(:id)).to eq([topic.id])

      # And delete it!
      expect {
        rating.update(topics_text: "\n")
      }.to change(described_class.jobs, :count).by(1)
      expect {
        instance.perform(rating.id)
      }.to change(described_class.jobs, :count).by(0)
      expect(rating.reload.topics_text).to be_nil
      expect(rating.topics.pluck(:id)).to eq([])
    end
    context "multiple topics" do
      let(:topics_text) { "Third Topic\nFirst topic\n\n Second topic\nFirst topic" }
      it "creates them all and orders alphabetically" do
        expect(Topic.count).to eq 0
        expect(rating).to be_valid
        expect {
          instance.perform(rating.id)
        }.to change(described_class.jobs, :count).by(0)

        expect(rating.reload.topics_text).to eq "First topic\nSecond topic\nThird Topic"
        expect(Topic.count).to eq 3
        # Update a topic without a slug change
        topic = Topic.friendly_find("third topic")
        expect {
          topic.update(name: "Third topic")
        }.to change(described_class.jobs, :count).by(1)
        instance.perform(rating.id)
        expect(rating.reload.topics_text).to eq "First topic\nSecond topic\nThird topic"
        # And then update *with* a slug change
        topic = Topic.friendly_find("second topic")
        expect {
          topic.update(name: "2nd topic")
        }.to change(described_class.jobs, :count).by(1)
        topic.reload
        expect(topic.name).to eq "2nd topic"
        instance.perform(rating.id)
        expect(rating.reload.topics_text).to eq "2nd topic\nFirst topic\nThird topic"
      end
    end
    context "topic_review" do
      let(:topic) { FactoryBot.create(:topic, name: "SOME COOL TOPIC") }
      let(:topic_review) { FactoryBot.create(:topic_review_active, topic: topic) }
      it "creates for the topic_review" do
        expect(topic_review.status).to eq "active"
        expect(rating.reload.topics.pluck(:id)).to eq([])
        expect(TopicReviewVote.count).to eq 0
        instance.perform(rating.id)
        expect(TopicReviewVote.count).to eq 1
        expect(rating.reload.topics.pluck(:id)).to eq([topic.id])
        expect(rating.topic_review_votes.count).to eq 1
        topic_review_vote = TopicReviewVote.last
        expect(topic_review_vote.rating_id).to eq rating.id
        expect(topic_review_vote.topic.id).to eq topic.id
        expect(topic_review_vote.vote_score).to eq 1
        rating.update(topics_text: "not the same topic")
        instance.perform(rating.id)
        rating.reload
        expect(rating.topics.count).to eq 1
        expect(rating.topic_names).to eq(["not the same topic"])
        expect(TopicReviewVote.pluck(:id)).to eq([])
      end
      context "inactive" do
        let(:topic_review) { FactoryBot.create(:topic_review, topic: topic) }
        it "doesn't create" do
          expect(topic_review.status).to eq "pending"
          expect(rating.reload.topics.pluck(:id)).to eq([])
          expect(TopicReviewVote.count).to eq 0
          instance.perform(rating.id)
          expect(TopicReviewVote.count).to eq 0
          expect(rating.reload.topics.pluck(:id)).to eq([topic.id])
          topic_review_vote = FactoryBot.create(:topic_review_vote, topic: topic, rating: rating)
          tiv_id = topic_review_vote.id
          instance.perform(rating.id)
          expect(TopicReviewVote.pluck(:id)).to eq([tiv_id])
          expect(topic_review.topic_review_votes.pluck(:id)).to eq([tiv_id])
        end
      end
    end
  end
end
