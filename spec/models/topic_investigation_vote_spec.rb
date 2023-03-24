require "rails_helper"

RSpec.describe TopicInvestigationVote, type: :model do
  describe "factory" do
    let(:topic_investigation_vote) { FactoryBot.create(:topic_investigation_vote) }
    it "is valid" do
      expect(topic_investigation_vote).to be_valid
      expect(topic_investigation_vote.user).to be_present
      expect(topic_investigation_vote.manual_rank).to be_falsey
      expect(topic_investigation_vote.topic_name).to eq topic_investigation_vote.topic_investigation.topic_name
      expect(topic_investigation_vote.review.topics_text).to match(topic_investigation_vote.topic_name)
      # Because we don't automatically run the ReconcileReviewTopicsJob
      expect(topic_investigation_vote.review.topics.pluck(:id)).to eq([topic_investigation_vote.topic.id])
    end
  end

  describe "skip_calculated_vote_score" do
    let(:topic_investigation_vote) { FactoryBot.create(:topic_investigation_vote, vote_score: 5, skip_calculated_vote_score: true) }
    it "assigns without calculate" do
      expect(topic_investigation_vote.reload.vote_score).to eq 5
    end
  end

  describe "vote_ordered" do
    let!(:tiv3) { FactoryBot.create(:topic_investigation_vote, vote_score: 1001, skip_calculated_vote_score: true) }
    let(:topic_investigation) { tiv3.user }
    let(:user) { tiv3.user }
    let(:topic) { tiv3.topic }
    let!(:tiv1) { FactoryBot.create(:topic_investigation_vote, vote_score: 1, user: user, topic: topic, skip_calculated_vote_score: true) }
    let!(:tiv2) { FactoryBot.create(:topic_investigation_vote, vote_score: 2, user: user, topic: topic, skip_calculated_vote_score: true) }
    let!(:tiv0) { FactoryBot.create(:topic_investigation_vote, vote_score: -5, user: user, topic: topic, skip_calculated_vote_score: true) }
    let(:vote_ordered_ids) { [tiv3.id, tiv2.id, tiv1.id, tiv0.id] }
    it "orders" do
      # Verify all on same topic_investigation and same user
      expect(topic_investigation.topic_investigation_votes.order(:id).pluck(:id)).to eq([tiv3.id, tiv1.id, tiv2.id, tiv0.id])
      expect(user.topic_investigation_votes.order(:id).pluck(:id)).to eq([tiv3.id, tiv1.id, tiv2.id, tiv0.id])
      expect(tiv3.reload.vote_score).to eq 1001
      expect(user.topic_investigation_votes.vote_ordered.pluck(:id)).to eq vote_ordered_ids
      expect(user.topic_investigation_votes.vote_ordered.recommended.pluck(:id)).to eq(vote_ordered_ids - [tiv0.id])
    end
  end

  describe "calculate_vote_score" do
    let(:topic) { FactoryBot.create(:topic) }
    let(:review) { FactoryBot.create(:review_with_topic, topics_text: topic.name) }
    let(:topic_investigation_vote) { FactoryBot.create(:topic_investigation_vote, topic: topic, review: review) }
    let(:user) { review.user }
    it "calculates" do
      expect(review.default_vote_score).to eq 0
      expect(topic_investigation_vote.calculated_vote_score).to eq 1
      expect(topic_investigation_vote.vote_score).to eq 1
      expect(topic_investigation_vote.recommended).to be_truthy
    end
    describe "second review" do
      let(:topic_investigation_vote2) { FactoryBot.create(:topic_investigation_vote, topic: topic, user: user) }
      let(:vote_ids) { [topic_investigation_vote.id, topic_investigation_vote2.id] }
      let(:review2) { topic_investigation_vote2.review }
      let(:review_ids) { [review.id, review2.id] }
      it "is one hire" do
        expect(topic_investigation_vote).to be_valid
        expect(topic_investigation_vote2).to be_valid
        expect(topic_investigation_vote2.topic_investigation_id).to eq topic_investigation_vote.topic_investigation_id
        expect(user.reload.topic_investigation_votes.order(:id).pluck(:id)).to eq vote_ids
        expect(topic.reload.topic_investigation_votes.order(:id).pluck(:id)).to eq vote_ids
        expect(topic_investigation_vote.reload.prev_topic_user_reviews.pluck(:id)).to eq([])
        expect(topic_investigation_vote.investigation_user_votes.order(:id).pluck(:id)).to eq vote_ids
        expect(topic_investigation_vote.topic_user_reviews.order(:id).pluck(:id)).to eq review_ids
        expect(topic_investigation_vote.calculated_vote_score).to eq 1
        expect(topic_investigation_vote2.reload.topic_user_reviews.order(:id).pluck(:id)).to eq review_ids
        expect(topic_investigation_vote2.id).to be > topic_investigation_vote.id
        expect(topic_investigation_vote2.prev_topic_user_reviews.pluck(:id)).to eq([review.id])
        expect(topic_investigation_vote2.calculated_vote_score).to eq 2
      end
      describe "review is high quality" do
        let(:review) { FactoryBot.create(:review_with_topic, topics_text: topic.name, quality: "quality_high") }
        it "they are in different tranches" do
          expect(review.default_vote_score).to eq 1000
          expect(topic_investigation_vote).to be_valid
          expect(topic_investigation_vote2).to be_valid
          expect(topic_investigation_vote2.review.default_vote_score).to eq 0
          expect(user.reload.topic_investigation_votes.order(:id).pluck(:id)).to eq vote_ids
          expect(topic.reload.topic_investigation_votes.order(:id).pluck(:id)).to eq vote_ids
          expect(topic_investigation_vote.reload.topic_user_reviews.order(:id).pluck(:id)).to eq review_ids
          expect(topic_investigation_vote.calculated_vote_score).to eq 1001
          expect(topic_investigation_vote2.reload.topic_user_reviews.order(:id).pluck(:id)).to eq review_ids
          expect(topic_investigation_vote2.prev_topic_user_reviews.pluck(:id)).to eq([review.id])
          expect(topic_investigation_vote2.calculated_vote_score).to eq 1
        end
      end
      describe "review is low quality" do
        let(:review) { FactoryBot.create(:review_with_topic, topics_text: topic.name, quality: "quality_low") }
        it "they are in different tranches" do
          expect(review.default_vote_score).to eq(-1000)
          expect(topic_investigation_vote).to be_valid
          expect(topic_investigation_vote2).to be_valid
          expect(topic_investigation_vote2.review.default_vote_score).to eq 0
          expect(topic_investigation_vote.calculated_vote_score).to eq(-999)
          expect(topic_investigation_vote2.calculated_vote_score).to eq 1
        end
      end
    end
  end
end
