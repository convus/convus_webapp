class ReviewsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!

  def new
    @review ||= Review.new
  end

  def create
    @review = Review.new(permitted_create_params)
    if @review.save
      flash[:success] = "Review created"
      redirect_to root_path, status: :see_other
    else
      render :new
    end
  end

  private

  def permitted_create_params
    params.require(:review).permit(:submitted_url, :agreement, :quality, :changed_my_opinion,
      :inaccuracies, :comment, :topics)
      .merge(user_id: current_user.id)
  end
end
