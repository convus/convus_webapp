class ReviewsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: [:index]
  before_action :find_topic_review, except: [:index]

  def index
    @topic_review = TopicReview.primary
    @topic_review_votes = user_topic_review_votes
    # @page_title = "#{viewing_display_name.titleize} reviews - Convus"
  end

  def update
  end

  private

  def find_topic_review
    @topic_review = TopicReview.friendly_find(params[:id])
  end

  def user_topic_review_votes
    return [] unless current_user.present?
    current_user.topic_review_votes.where(topic_review_id: @topic_review.id)
      .includes(:rating)
  end
end
