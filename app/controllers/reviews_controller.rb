class ReviewsController < ApplicationController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: %i[index]
  before_action :redirect_to_signup_unless_user_present!, except: %i[new index]
  before_action :find_and_authorize_review, only: %i[edit update destroy]

  def index
    if current_user.blank? && (user_subject.blank? || user_subject.reviews_private)
      redirect_to_signup_unless_user_present!
      return
    elsif user_subject.blank?
      redirect_to reviews_path(user: current_user.username)
      return
    elsif user_subject.reviews_private && user_subject != current_user
      flash[:error] = "You don't have permission to view those reviews"
      redirect_to user_root_url, status: :see_other
      return
    end
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @reviews = searched_requests.reorder("reviews.#{sort_column} #{sort_direction}")
      .includes(:citation).page(page).per(@per_page)
  end

  def new
    @source = params[:source].presence || "web"
    @no_layout = @source != "web"
    @review ||= Review.new(source: @source)
    if @source == "web"
      redirect_to_signup_unless_user_present!
    elsif @source == "turbo_stream"
      render layout: false
    end
  end

  def create
    @review = Review.new(permitted_params)
    @review.user = current_user
    if @review.save
      respond_to do |format|
        format.html do
          redirect_source = (@review.source == "web") ? nil : @review.source
          redirect_to new_review_path(source: redirect_source), status: :see_other, flash: {success: "Review added"}
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@review, partial: "reviews/form", locals: {review: @review}) }
        format.html do
          flash[:error] = "Review not created"
          render :new
        end
      end
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

  def destroy
    if @review.destroy
      flash[:success] = "Review deleted"
      redirect_to reviews_path, status: :see_other
    else
      flash[:error] = "Unable to delete review!"
      redirect_to edit_review_path(@review), status: :see_other
    end
  end

  private

  def permitted_params
    params.require(:review)
      .permit(:submitted_url, :citation_title, :agreement, :quality,
        :changed_my_opinion, :significant_factual_error, :error_quotes,
        :topics_text, :source)
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
      @review = review
    else
      flash[:error] = "Unable to find that review"
      redirect_to(user_root_url) && return
    end
  end
end
