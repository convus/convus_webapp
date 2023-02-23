class ReviewsController < ApplicationController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: %i[index]
  before_action :redirect_to_signup_unless_user_present!

  def index
    if params[:user] != current_user.username
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
    params.require(:review)
      .permit(:submitted_url, :citation_title, :agreement, :quality,
        :changed_my_opinion, :significant_factual_error, :error_quotes,
        :topics)
      .merge(user_id: current_user.id)
  end

  def sortable_columns
    %w[created_at] # TODO: Add agreement and quality
  end

  def searched_requests
    reviews = user_subject.reviews

    @time_range_column = "created_at"
    reviews.where(@time_range_column => @time_range)
  end
end
