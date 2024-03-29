class ReviewsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]
  before_action :find_topic_review, except: [:index]
  before_action { @controller_display_name = "Topic Review" }

  def index
    @topic_reviews = TopicReview.ended.order(end_at: :desc)
    @action_display_name = "Topic reviews - Convus"
  end

  def show
    @topic_review_votes = user_topic_review_votes.vote_ordered
    @action_display_name = @topic_review.display_name
    @topic_review_citations = @topic_review.topic_review_citations.vote_ordered
  end

  def update
    flash[:success] = "Rankings updated"
    vote_ranks = VoteScoreUpdater.params_to_vote_ranks(current_user, @topic_review, params)
    VoteScoreUpdater.update_scores(current_user, @topic_review, vote_ranks)
    redirect_back(fallback_location: review_path(@topic_review.slug, status: :see_other))
  end

  private

  def find_topic_review
    @topic_review = TopicReview.friendly_find!(params[:id])
  end

  def user_topic_review_votes
    return TopicReviewVote.none if current_user.blank?
    current_user.topic_review_votes.where(topic_review_id: @topic_review.id)
      .includes(:rating)
  end
end
