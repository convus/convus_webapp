require "rails_helper"

RSpec.describe TopicReviewVote, type: :model do
  describe "factory" do
    let(:topic_review_vote) { FactoryBot.create(:topic_review_vote) }
    it "is valid" do
      expect(topic_review_vote).to be_valid
      expect(topic_review_vote.user).to be_present
      expect(topic_review_vote.manual_rank).to be_falsey
      expect(topic_review_vote.topic_name).to eq topic_review_vote.topic_review.topic_name
      expect(topic_review_vote.rating.topics_text).to match(topic_review_vote.topic_name)
      # Because we don't automatically run the ReconcileRatingTopicsJob
      expect(topic_review_vote.rating.topics.pluck(:id)).to eq([topic_review_vote.topic.id])
    end
  end

  describe "skip_calculated_vote_score" do
    let(:topic_review_vote) { FactoryBot.create(:topic_review_vote, vote_score: 5, skip_calculated_vote_score: true) }
    it "assigns without calculate" do
      expect(topic_review_vote.reload.vote_score).to eq 5
    end
  end

  describe "vote_ordered" do
    let!(:tiv3) { FactoryBot.create(:topic_review_vote, vote_score: 1001, skip_calculated_vote_score: true) }
    let(:topic_review) { tiv3.user }
    let(:user) { tiv3.user }
    let(:topic) { tiv3.topic }
    let!(:tiv1) { FactoryBot.create(:topic_review_vote, vote_score: 1, user: user, topic: topic, skip_calculated_vote_score: true) }
    let!(:tiv2) { FactoryBot.create(:topic_review_vote, vote_score: 2, user: user, topic: topic, skip_calculated_vote_score: true) }
    let!(:tiv0) { FactoryBot.create(:topic_review_vote, vote_score: -5, user: user, topic: topic, skip_calculated_vote_score: true) }
    let(:vote_ordered_ids) { [tiv3.id, tiv2.id, tiv1.id, tiv0.id] }
    it "orders" do
      # Verify all on same topic_review and same user
      expect(topic_review.topic_review_votes.order(:id).pluck(:id)).to eq([tiv3.id, tiv1.id, tiv2.id, tiv0.id])
      expect(user.topic_review_votes.order(:id).pluck(:id)).to eq([tiv3.id, tiv1.id, tiv2.id, tiv0.id])
      expect(tiv3.reload.vote_score).to eq 1001
      expect(user.topic_review_votes.vote_ordered.pluck(:id)).to eq vote_ordered_ids
      expect(user.topic_review_votes.vote_ordered.recommended.pluck(:id)).to eq(vote_ordered_ids - [tiv0.id])
    end
  end

  describe "calculate_vote_score" do
    let(:topic) { FactoryBot.create(:topic) }
    let(:rating) { FactoryBot.create(:rating_with_topic, topics_text: topic.name) }
    let(:topic_review_vote) { FactoryBot.create(:topic_review_vote, topic: topic, rating: rating) }
    let(:user) { rating.user }
    it "calculates" do
      expect(rating.default_vote_score).to eq 0
      expect(topic_review_vote.calculated_vote_score).to eq 1
      expect(topic_review_vote.vote_score).to eq 1
      expect(topic_review_vote.recommended).to be_truthy
    end
    describe "second rating" do
      let(:topic_review_vote2) { FactoryBot.create(:topic_review_vote, topic: topic, user: user) }
      let(:vote_ids) { [topic_review_vote.id, topic_review_vote2.id] }
      let(:rating2) { topic_review_vote2.rating }
      let(:rating_ids) { [rating.id, rating2.id] }
      it "is one hire" do
        expect(topic_review_vote).to be_valid
        expect(topic_review_vote2).to be_valid
        expect(topic_review_vote2.topic_review_id).to eq topic_review_vote.topic_review_id
        expect(user.reload.topic_review_votes.order(:id).pluck(:id)).to eq vote_ids
        expect(topic.reload.topic_review_votes.order(:id).pluck(:id)).to eq vote_ids
        expect(topic_review_vote.reload.prev_topic_user_ratings.pluck(:id)).to eq([])
        expect(topic_review_vote.review_user_votes.order(:id).pluck(:id)).to eq vote_ids
        expect(topic_review_vote.topic_user_ratings.order(:id).pluck(:id)).to eq rating_ids
        expect(topic_review_vote.calculated_vote_score).to eq 1
        expect(topic_review_vote2.reload.topic_user_ratings.order(:id).pluck(:id)).to eq rating_ids
        expect(topic_review_vote2.id).to be > topic_review_vote.id
        expect(topic_review_vote2.prev_topic_user_ratings.pluck(:id)).to eq([rating.id])
        expect(topic_review_vote2.calculated_vote_score).to eq 2
      end
      describe "rating is high quality" do
        let(:rating) { FactoryBot.create(:rating_with_topic, topics_text: topic.name, quality: "quality_high") }
        it "they are in different tranches" do
          expect(rating.default_vote_score).to eq 1000
          expect(topic_review_vote).to be_valid
          expect(topic_review_vote2).to be_valid
          expect(topic_review_vote2.rating.default_vote_score).to eq 0
          expect(user.reload.topic_review_votes.order(:id).pluck(:id)).to eq vote_ids
          expect(topic.reload.topic_review_votes.order(:id).pluck(:id)).to eq vote_ids
          expect(topic_review_vote.reload.topic_user_ratings.order(:id).pluck(:id)).to eq rating_ids
          expect(topic_review_vote.calculated_vote_score).to eq 1001
          expect(topic_review_vote2.reload.topic_user_ratings.order(:id).pluck(:id)).to eq rating_ids
          expect(topic_review_vote2.prev_topic_user_ratings.pluck(:id)).to eq([rating.id])
          expect(topic_review_vote2.calculated_vote_score).to eq 1
        end
      end
      describe "rating is low quality" do
        let(:rating) { FactoryBot.create(:rating_with_topic, topics_text: topic.name, quality: "quality_low") }
        it "they are in different tranches" do
          expect(rating.default_vote_score).to eq(-1000)
          expect(topic_review_vote).to be_valid
          expect(topic_review_vote2).to be_valid
          expect(topic_review_vote2.rating.default_vote_score).to eq 0
          expect(topic_review_vote.calculated_vote_score).to eq(-999)
          expect(topic_review_vote2.calculated_vote_score).to eq 1
        end
      end
    end
  end
end
