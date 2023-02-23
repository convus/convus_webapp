class ReviewsController < ApplicationController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: %i[index]
  before_action :redirect_to_signup_unless_user_present!
  before_action :find_and_authorize_review, only: %i[edit update]

  def index
    if user_subject&.id != current_user.id
      redirect_to reviews_path(user: current_user.username)
      return
    end
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @reviews = searched_requests.reorder("reviews.#{sort_column} #{sort_direction}")
      .includes(:citation).page(page).per(@per_page)
  end

  def new
    @review ||= Review.new
  end

  def create
    @review = Review.new(permitted_params)
    @review.user = current_user
    if @review.save
      flash[:success] = "Review created"
      redirect_to root_path, status: :see_other
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @review.update(permitted_params)
      flash[:success] = "Review updated"
      redirect_to new_review_path, status: :see_other
    else
      render :edit
    end
  end

  private

  def permitted_params
    params.require(:review)
      .permit(:submitted_url, :citation_title, :agreement, :quality,
        :changed_my_opinion, :significant_factual_error, :error_quotes,
        :topics_text)
  end

  def sortable_columns
    %w[created_at] # TODO: Add agreement and quality
  end

  def searched_requests
    reviews = user_subject.reviews

    @time_range_column = "created_at"
    reviews.where(@time_range_column => @time_range)
  end

  def find_and_authorize_review
    review = current_user.reviews.where(id: params[:id]).first
    if review.present?
      return @review = review
    else
      flash[:error] = "Unable to find that review"
      redirect_to(user_root_url) && return
    end
  end
end
