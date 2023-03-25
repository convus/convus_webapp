require "rails_helper"

base_url = "/reviews"
RSpec.describe base_url, type: :request do
  let!(:topic_review) { FactoryBot.create(:topic_review) }

  context "index" do
    it "responds" do
      get base_url
      expect(response).to redirect_to(review_path(topic_review.slug))
      # TODO: once there are multiple topic_reviews, render this
      # expect(response.code).to eq "200"
      # expect(response).to render_template("reviews/index")
    end
  end

  context "show" do
    it "renders" do
      get "#{base_url}/#{topic_review.slug}"
      expect(response.code).to eq "200"
      expect(response).to render_template("reviews/show")
      expect(assigns(:topic_review)&.id).to eq topic_review.id
      expect(assigns(:topic_review_votes)&.pluck(:id)).to eq([])
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user
    let(:topic_review_vote) { FactoryBot.create(:topic_review_vote, topic_review: topic_review, user: current_user) }
    let(:topic_review_vote_offtopic) { FactoryBot.create(:topic_review_vote, user: current_user) }

    describe "index" do
      it "responds" do
        get base_url
        expect(response).to redirect_to(review_path(topic_review.slug))
        # TODO: once there are multiple topic_reviews, render this
        # expect(response.code).to eq "200"
        # expect(response).to render_template("reviews/index")
      end
    end

    describe "show" do
      before { expect([topic_review_vote.id, topic_review_vote_offtopic.id].size).to eq 2 }
      it "renders" do
        expect(current_user.reload.topic_review_votes.pluck(:id)).to eq([topic_review_vote.id, topic_review_vote_offtopic.id])
        get "#{base_url}/#{topic_review.id}"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/show")
        expect(assigns(:topic_review)&.id).to eq topic_review.id
        expect(assigns(:topic_review_votes)&.pluck(:id)).to eq([topic_review_vote.id])
      end
    end
  end
end
