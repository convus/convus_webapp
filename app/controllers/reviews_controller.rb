class ReviewsController < ApplicationController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: %i[index]
  before_action :redirect_to_signup_unless_user_present!, except: %i[new index]
  before_action :find_and_authorize_review, only: %i[edit update destroy]

  def index
    raise ActiveRecord::RecordNotFound if user_subject.blank?
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @reviews = viewable_reviews.reorder("reviews.#{sort_column} #{sort_direction}")
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
    @review = Review.new(permitted_create_params)
    @review.user = current_user
    if @review.save
      respond_to do |format|
        format.html do
          flash.now[:success] = "Review added"
          redirect_source = (@review.source == "web") ? nil : @review.source
          redirect_to new_review_path(source: redirect_source), status: :see_other
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
    params.require(:review).permit(*permitted_attrs)
  end

  def permitted_create_params
    params.require(:review).permit(*(permitted_attrs + [:timezone]))
  end

  def permitted_attrs
    %i[agreement changed_my_opinion citation_title did_not_understand
      error_quotes learned_something quality significant_factual_error
      source submitted_url topics_text]
  end

  def sortable_columns
    %w[created_at] # TODO: Add agreement and quality
  end

  def viewable_reviews
    @reviews_private = user_subject.reviews_private
    @can_view_reviews = user_subject.reviews_public || user_subject == current_user
    @can_view_reviews ? searched_reviews : Review.none
  end

  def searched_reviews
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
