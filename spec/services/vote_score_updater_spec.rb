require "rails_helper"

RSpec.describe VoteScoreUpdater do
  def score_hash_to_rating_ranks(hash)
    rating_ranks = hash[:constructive]
    offset = Rating::RANK_OFFSET - TopicReviewVote::RENDERED_OFFSET - hash[:constructive].keys.count
    required = hash[:required].to_a.map { |i_r| [i_r[0], i_r[1] - offset] }.to_h
    not_recommended = hash[:not_recommended].to_a.map { |i_r| [i_r[0], i_r[1] + 1000]}.to_h
    rating_ranks.merge(not_recommended).merge(required)
  end

  describe "params_to_rating_ranks" do
    let(:phash) do
      {"_method"=>"patch", "rank_rating_166"=>"17", "rank_rating_69"=>"6", "rank_rating_70"=>"5",
        "rank_rating_131"=>"4", "rank_rating_169"=>"3", "rank_rating_175"=>"2", "rank_rating_173"=>"1",
        "rank_rating_105"=>"-1", "rank_rating_198"=>"-2", "button"=>"", "controller"=>"reviews",
        "action"=>"update", "id"=>"dc-statehood"}
    end
    let(:passed_params) { ActionController::Parameters.new(phash) }
    let(:target) do
      {
        "166"=> 17, "69"=> 6, "70"=> 5, "131"=> 4, "169"=> 3, "175"=> 2, "173"=> 1,
        "105"=> -1, "198"=> -2
      }
    end
    it "returns score hash" do
      expect(described_class.params_to_rating_ranks(passed_params)).to eq target
    end
  end

  describe "normalize_score_hash" do
    let(:normalized) do
      {
        required: {"166"=> 1002, "69"=> 1001},
        constructive: {"70"=> 3, "131"=> 2, "169"=> 1},
        not_recommended: {"105"=> -1001, "198"=> -1002}
      }
    end
    let(:rating_ranks) { score_hash_to_rating_ranks(normalized) }

    it "returns itself" do
      target_rating_ranks = {"166"=> 15, "69"=> 14, "70"=> 3, "131"=> 2,
        "169"=> 1, "105"=> -1, "198"=> -2}
      # Verify that the transformation works correctly
      expect(score_hash_to_rating_ranks(normalized)).to eq  target_rating_ranks
      expect_hashes_to_match(described_class.normalize_score_hash(score_hash_to_rating_ranks(normalized)), normalized)
      expect_hashes_to_match(described_class.normalize_score_hash(rating_ranks), normalized)
      expect(described_class.normalize_score_hash(rating_ranks)).to eq normalized
    end
    context "required higher" do
      let(:passed) { rating_ranks.merge("166"=> 19, "69"=> 17) }
      it "returns normalized" do
        expect_hashes_to_match(described_class.normalize_score_hash(passed), normalized)
        expect(described_class.normalize_score_hash(passed)).to eq normalized
      end
    end
    context "bigger variance" do
      let(:passed) { rating_ranks.merge("166"=> 30, "69"=> 29, "105"=> 0, "198"=> -20) }
      it "returns normalized" do
        expect_hashes_to_match(described_class.normalize_score_hash(passed), normalized)
        expect(described_class.normalize_score_hash(passed)).to eq normalized
      end
    end
    context "only required, no constructive" do
      let(:normalized) do
        {
          required: {"166"=> 1005, "69"=> 1004, "70"=> 1003, "131"=> 1002, "169"=> 1001},
          constructive: {},
          not_recommended: {"105"=> -1001, "198"=> -1002}
        }
      end
      let(:passed) { rating_ranks.merge("166"=> 26, "69"=> 20, "169"=> 9, "198"=> -20) }
      it "returns normalized" do
        expect_hashes_to_match(described_class.normalize_score_hash(passed), normalized)
        expect(described_class.normalize_score_hash(passed)).to eq normalized
      end
    end
  end

  describe "update" do
    let(:rating_required2) { FactoryBot.create(:rating_with_topic, quality: :quality_high) }
    let(:user) { rating_required2.user }
    let(:topic) { rating_required2.topics.first }
    let(:rating_required1) { FactoryBot.create(:rating_with_topic, user: user, topic: topic, quality: :quality_high) }
    let(:rating_constructive) { FactoryBot.create(:rating_with_topic, user: user, topic: topic, quality: :quality_med) }
    let(:rating_not_recommended) { FactoryBot.create(:rating_with_topic, user: user, topic: topic, quality: :quality_low) }

    let!(:vote_required2) { FactoryBot.create(:topic_review_vote, rating: rating_required2, topic: topic) }
    let(:topic_review) { vote_required2.topic_review }
    let!(:vote_required1) { FactoryBot.create(:topic_review_vote, rating: rating_required1, topic: topic) }
    let!(:vote_constructive) { FactoryBot.create(:topic_review_vote, rating: rating_constructive, topic: topic) }
    let!(:vote_not_recommended) { FactoryBot.create(:topic_review_vote, rating: rating_not_recommended, topic: topic) }
    let!(:vote_not_recommended2) { FactoryBot.create(:topic_review_vote, user: user, quality: :quality_low, topic: topic) }
    let(:vote_other_user) { FactoryBot.create(:topic_review_vote, topic: topic, quality: "quality_high") }
    let(:vote_other_topic) { FactoryBot.create(:topic_review_vote, user: user, quality: "quality_high") }
    let(:vote_ids) { [vote_required1.id, vote_required2.id, vote_constructive.id, vote_not_recommended.id, vote_not_recommended2.id] }
    let(:topic_review_votes) { user.topic_review_votes.where(topic_review_id: topic_review.id).vote_ordered }
    let(:initial_score_hash) do
      {
        required: {vote_required1.id.to_s => 2, vote_required2.id.to_s => 1},
        constructive: {vote_constructive.id.to_s => 1},
        not_recommended: {vote_not_recommended2.id => -1, vote_not_recommended.id.to_s => -2}
      }
    end
    let(:rating_ranks) { score_hash_to_rating_ranks(initial_score_hash) }
    xit "updates when changed" do
      expect(rating_required1.reload.topics.pluck(:id)).to eq([topic.id])
      expect(rating_required2.reload.default_vote_score).to eq 1000
      expect(vote_other_user && vote_other_topic).to be_present
      expect(TopicReviewVote.vote_ordered.pluck(:id)).to match_array([vote_other_user.id, vote_other_topic.id] + vote_ids)
      expect(user.reload.topic_review_votes.vote_ordered.pluck(:id)).to match_array([vote_other_topic.id] + vote_ids)
      expect(topic_review_votes.pluck(:id)).to eq(vote_ids)
      # ordering things
      expect(topic_review_votes.pluck(:vote_score)).to eq([1002, 1001, 1, -1001])
      expect(vote_required1.vote_score).to eq 1002
      expect(described_class.default_score_hash(topic_review_votes)).to eq initial_score_hash
      # Update without any changes
      # described_class.update_scores(user, topic_review, rating_ranks)
      # expect(topic_review_votes.reload.pluck(:id, :vote_score).flatten).to eq([vote_required1.id, 1002, vote_required2.id, 1001, vote_constructive.id, 1, vote_not_recommended.id, -999])
      # expect(topic_review_votes.manual_score.any?).to be_falsey
      # Update changing the required
      described_class.update_scores(user, topic_review, rating_ranks.merge(vote_required2.id.to_s => 14))
      expect(topic_review_votes.reload.pluck(:id, :vote_score).flatten).to eq([vote_required2.id, 1502, vote_required1.id, 1501, vote_constructive.id, 1, vote_not_recommended.id, -999])
      expect(topic_review_votes.manual_score.any?).to be_truthy
      expect(topic_review_votes.where.not(id: vote_required2.id).manual_score.any?).to be_falsey
      # Update to go back to default scores
      described_class.update_scores(user, topic_review, rating_ranks.merge(vote_required1.id.to_s => 15))
      expect(topic_review_votes.reload.pluck(:id, :vote_score).flatten).to eq([vote_required1.id, 1002, vote_required2.id, 1001, vote_constructive.id, 1, vote_not_recommended.id, -999])
      expect(topic_review_votes.manual_score.any?).to be_falsey
    end
  end
end
