require "rails_helper"

RSpec.describe TopicReviewCitation, type: :model do
  describe "factory" do
    let(:topic_review_citation) { FactoryBot.create(:topic_review_citation) }
    it "is valid" do
      expect(topic_review_citation).to be_valid
      expect(topic_review_citation.reload.topic_review_votes.count).to eq 0
      expect(topic_review_citation.vote_score).to eq(-1000)
      expect(topic_review_citation.vote_score_manual).to be_nil
      expect(topic_review_citation.auto_score?).to be_truthy
    end
    context "topic_review_vote" do
      let(:topic_review_vote) { FactoryBot.create(:topic_review_vote_with_citation) }
      let(:topic_review_citation) { topic_review_vote.topic_review_citation }
      it "creates" do
        expect(TopicReviewCitation.count).to eq 0
        expect(topic_review_vote).to be_valid
        expect(TopicReviewCitation.count).to eq 1
        expect(topic_review_citation).to be_valid
        expect(topic_review_citation.reload.topic_review_votes.count).to eq 1
        expect(TopicReview.count).to eq 1
      end
    end
  end

  describe "vote_score_calculated" do
    let(:topic) { FactoryBot.create(:topic) }
    let(:time) { Time.current - 2.days }
    let(:rating) { FactoryBot.create(:rating_with_topic, topics_text: topic.name, created_at: time, quality: quality) }
    let(:quality) { :quality_med }
    let(:topic_review_vote) { FactoryBot.create(:topic_review_vote, topic: topic, rating: rating) }
    let(:user) { rating.user }
    let(:topic_review_citation) { topic_review_vote.update_topic_review_citation }
    let(:citation) { topic_review_citation.citation }
    it "calculates" do
      expect(rating.default_vote_score).to eq 0
      expect(topic_review_vote.vote_score_calculated).to eq 1
      expect(topic_review_vote.vote_score).to eq 1
      expect(topic_review_vote.rank).to eq "constructive"
      expect(topic_review_vote.recommended?).to be_truthy
      expect(topic_review_citation.vote_score_calculated).to eq 1
      topic_review_citation.update(updated_at: Time.current)
      expect(topic_review_citation.vote_score).to eq 1
    end
    describe "A high quality vote" do
      let(:topic_review_vote2) do
        # Normally topic_review_citation is assigned via ReconcileRatingTopicsJob -
        # which recalcs votes if required
        FactoryBot.create(:topic_review_vote,
          quality: :quality_high,
          topic: topic,
          topic_review_citation: topic_review_citation,
          citation: citation)
      end
      it "calculates" do
        expect(topic_review_vote.vote_score_calculated).to eq 1
        expect(topic_review_vote.vote_score).to eq 1
        expect(topic_review_vote2.vote_score_calculated).to eq 1001
        expect(topic_review_vote2.vote_score).to eq 1001
        expect(topic_review_citation.reload.vote_score_calculated).to eq 501
        expect(topic_review_citation.needs_update?).to be_truthy
        topic_review_citation.update(updated_at: Time.current)
        expect(topic_review_citation.vote_score).to eq 501
      end
      context "vote_score_manual" do
        it "needs_update? false" do
          expect(topic_review_vote.vote_score_calculated).to eq 1
          expect(topic_review_vote.vote_score).to eq 1
          topic_review_citation.update(vote_score_manual: 69)
          expect(topic_review_vote2.vote_score_calculated).to eq 1001
          expect(topic_review_vote2.vote_score).to eq 1001
          expect(topic_review_citation.reload.vote_score_calculated).to eq 501
          expect(topic_review_citation.needs_update?).to be_falsey
          topic_review_citation.update(updated_at: Time.current)
          expect(topic_review_citation.vote_score).to eq 69
        end
      end
    end
  end

  describe "creation via ReconcileRatingTopicsJob" do
    let(:topic_review) { FactoryBot.create(:topic_review_active) }
    let!(:topic) { topic_review.topic }
    let!(:rating) { FactoryBot.create(:rating, quality: :quality_high) }
    let(:citation) { rating.citation }
    let(:rating2) { FactoryBot.create(:rating, submitted_url: citation.url) }
    it "sets stuff up" do
      expect(topic_review.reload.topic_review_citations.count).to eq 0
      expect(rating2.citation_id).to eq citation.id
      expect(citation.topics.pluck(:id)).to eq([])
      Sidekiq::Worker.clear_all
      rating.add_topic(topic)
      expect(ReconcileRatingTopicsJob.jobs.count).to eq 1
      Sidekiq::Worker.clear_all
      ReconcileRatingTopicsJob.new.perform(rating.id, rating)
      expect(ReconcileRatingTopicsJob.jobs.map { |j| j["args"] }.flatten).to eq([rating2.id])
      ReconcileRatingTopicsJob.drain
      expect(ReconcileRatingTopicsJob.jobs.count).to eq 0
      expect(citation.reload.topics.pluck(:id)).to eq([topic.id])
      expect(citation.topics.pluck(:id)).to eq([topic.id])
      expect(rating.reload.topic_review_votes.count).to eq 1
      expect(rating2.reload.topic_review_votes.count).to eq 1
      expect(topic_review.reload.topic_review_citations.count).to eq 1
      topic_review_citation = topic_review.topic_review_citations.first
      expect(topic_review_citation.topic_review_votes.count).to eq 2
      expect(topic_review_citation.vote_score).to eq 1001
      rating.remove_topic(topic)
      expect(topic_review_citation.reload.topic_review_votes.count).to eq 2
      expect(topic_review_citation.vote_score).to eq 1001
    end
  end
end
