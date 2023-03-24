class ReviewsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: [:index]
  before_action :find_topic_review, except: [:index]

  def index
    @topic_review = TopicReview.primary
    # @page_title = "#{viewing_display_name.titleize} reviews - Convus"
  end

  def show
  end

  def update
  end

  private

  def find_topic_review
    @topic_review = TopicReview.friendly_find(params[:id])
  end
end
