require 'rails_helper'

RSpec.describe TopicReviewCitation, type: :model do
  describe "factory" do
    let(:topic_review_citation) { FactoryBot.create(:topic_review_citation) }
    it "is valid" do
      expect(topic_review_citation).to be_valid
      expect(topic_review_citation.vote_score).to eq 0
      expect(topic_review_citation.vote_score_manual).to be_nil
      expect(topic_review_citation.auto_score?).to be_truthy
    end
    context "topic_review_vote" do
      let(:topic_review_vote) { FactoryBot.build(:topic_review_vote) }
      let(:topic_review_citation) { topic_review_vote.topic_review_citation }
      it "creates" do
        expect {
          topic_review_vote.save
        }.to change(TopicReviewCitation, :count).by 1
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
    let(:topic_review_citation) { topic_review_vote.topic_review_citation }
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
      let(:topic_review_vote2) { FactoryBot.create(:topic_review_vote, quality: :quality_high, topic: topic, citation: citation) }
      it "calculates" do
        expect(topic_review_vote.vote_score_calculated).to eq 1
        expect(topic_review_vote.vote_score).to eq 1
        expect(topic_review_vote2.vote_score_calculated).to eq 1001
        expect(topic_review_vote2.vote_score).to eq 1001
        expect(topic_review_citation.vote_score_calculated).to eq 501
        topic_review_citation.update(updated_at: Time.current)
        expect(topic_review_citation.vote_score).to eq 501
      end
    end
    # describe "2 low quality" do
    #   let(:topic_review_vote2) { FactoryBot.create(:topic_review_vote, topic: topic, user: user, quality: :quality_low) }
    #   let(:topic_review_vote3) { FactoryBot.create(:topic_review_vote, topic: topic, user: user, quality: :quality_low) }
    #   let(:vote_ids) { [topic_review_vote.id, topic_review_vote2.id, topic_review_vote3.id] }
    #   it "has expected scores" do
    #     expect(topic_review_vote.reload.vote_score).to eq(1001)
    #     expect(topic_review_vote2.reload.vote_score_calculated).to eq(-1001)
    #     expect(topic_review_vote2.vote_score).to eq(-1001)
    #     expect(topic_review_vote3.reload.vote_score_calculated).to eq(-1001)
    #     expect(topic_review_vote3.vote_score).to eq(-1001)
    #     user_topic_votes = user.reload.topic_review_votes.where(topic_review_id: topic_review_vote.topic_review_id)
    #     expect(user_topic_votes.vote_ordered.pluck(:id)).to eq vote_ids
    #     expect(topic_review_vote.reload.vote_score_calculated).to eq(-1003)
    #     topic_review_vote.update(updated_at: Time.current)
    #     expect(topic_review_vote.vote_score).to eq(-1003)
    #     topic_review_vote2.reload.update(updated_at: Time.current)
    #     expect(topic_review_vote2.vote_score).to eq(-1002)
    #     topic_review_vote3.reload.update(updated_at: Time.current)
    #     expect(topic_review_vote3.vote_score).to eq(-1001)
    #   end
    # end
  end
end
