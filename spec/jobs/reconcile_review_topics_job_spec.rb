# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReconcileReviewTopicsJob, type: :job do
  let(:instance) { described_class.new }
  let(:review) { FactoryBot.create(:review, topics_text: topics_text) }
  let(:topics_text) { " Some cool topic\n\n" }
  let(:citation) { review.citation }

  describe "#perform" do
    before { Sidekiq::Worker.clear_all }
    it "creates the topics" do
      expect(Topic.count).to eq 0
      expect {
        expect(review).to be_valid
      }.to change(described_class.jobs, :count).by(1)
      expect {
        instance.perform(review.id)
      }.to change(described_class.jobs, :count).by(0)
      expect(Topic.count).to eq 1
      topic = Topic.last
      expect(topic.name).to eq "Some cool topic"
      expect(review.reload.topics_text).to eq topic.name
      expect(review.topics.pluck(:id)).to eq([topic.id])

      # And delete it!
      expect {
        review.update(topics_text: "\n")
      }.to change(described_class.jobs, :count).by(1)
      expect {
        instance.perform(review.id)
      }.to change(described_class.jobs, :count).by(0)
      expect(review.reload.topics_text).to be_nil
      expect(review.topics.pluck(:id)).to eq([])
    end
    context "multiple topics" do
      let(:topics_text) { "Third Topic\nFirst topic\n\n Second topic\nFirst topic" }
      it "creates them all and orders alphabetically" do
        expect(Topic.count).to eq 0
        expect(review).to be_valid
        expect {
          instance.perform(review.id)
        }.to change(described_class.jobs, :count).by(0)

        expect(review.reload.topics_text).to eq "First topic\nSecond topic\nThird Topic"
        expect(Topic.count).to eq 3
        # Update a topic without a slug change
        topic = Topic.friendly_find("third topic")
        expect {
          topic.update(name: "Third topic")
        }.to change(described_class.jobs, :count).by(1)
        instance.perform(review.id)
        expect(review.reload.topics_text).to eq "First topic\nSecond topic\nThird topic"
        # And then update *with* a slug change
        topic = Topic.friendly_find("second topic")
        expect {
          topic.update(name: "2nd topic")
        }.to change(described_class.jobs, :count).by(1)
        topic.reload
        expect(topic.name).to eq "2nd topic"
        instance.perform(review.id)
        expect(review.reload.topics_text).to eq "2nd topic\nFirst topic\nThird topic"
      end
    end
    context "topic_investigation" do
      let(:topic) { FactoryBot.create(:topic, name: "SOME COOL TOPIC") }
      let(:topic_investigation) { FactoryBot.create(:topic_investigation_active, topic: topic) }
      it "creates for the topic_investigation" do
        expect(topic_investigation.status).to eq "active"
        expect(review.reload.topics.pluck(:id)).to eq([])
        expect(TopicInvestigationVote.count).to eq 0
        instance.perform(review.id)
        expect(TopicInvestigationVote.count).to eq 1
        expect(review.reload.topics.pluck(:id)).to eq([topic.id])
        expect(review.topic_investigation_votes.count).to eq 1
        topic_investigation_vote = TopicInvestigationVote.last
        expect(topic_investigation_vote.review_id).to eq review.id
        expect(topic_investigation_vote.topic.id).to eq topic.id
        expect(topic_investigation_vote.listing_order).to eq 1
        review.update(topics_text: "not the same topic")
        instance.perform(review.id)
        review.reload
        expect(review.topics.count).to eq 1
        expect(review.topic_names).to eq(["not the same topic"])
        expect(TopicInvestigationVote.pluck(:id)).to eq([])
      end
      context "inactive" do
        let(:topic_investigation) { FactoryBot.create(:topic_investigation, topic: topic) }
        it "doesn't create" do
          expect(topic_investigation.status).to eq "pending"
          expect(review.reload.topics.pluck(:id)).to eq([])
          expect(TopicInvestigationVote.count).to eq 0
          instance.perform(review.id)
          expect(TopicInvestigationVote.count).to eq 0
          expect(review.reload.topics.pluck(:id)).to eq([topic.id])
          topic_investigation_vote = FactoryBot.create(:topic_investigation_vote, topic: topic, review: review)
          tiv_id = topic_investigation_vote.id
          instance.perform(review.id)
          expect(TopicInvestigationVote.pluck(:id)).to eq([tiv_id])
          expect(topic_investigation.topic_investigation_votes.pluck(:id)).to eq([tiv_id])
        end
      end
    end
  end
end
