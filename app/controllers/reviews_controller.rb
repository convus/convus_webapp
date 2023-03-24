class ReviewsController < ApplicationController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: %i[index]
  before_action :redirect_to_signup_unless_user_present!, except: %i[new index]
  before_action :find_and_authorize_review, only: %i[edit update destroy]
  helper_method :viewing_display_name

  def index
    if viewing_display_name == "following" && current_user.blank?
      redirect_to_signup_unless_user_present!
      return
    end
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @reviews = viewable_reviews.reorder("reviews.#{sort_column} #{sort_direction}")
      .includes(:citation, :user).page(page).per(@per_page)
    if params[:search_assign_topic].present?
      @assign_topic = Topic.friendly_find(params[:search_assign_topic])
    end
    @page_title = "#{viewing_display_name.titleize} reviews - Convus"
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
          flash[:success] = "Review added"
          redirect_source = (@review.source == "web") ? nil : @review.source
          redirect_to new_review_path(source: redirect_source), status: :see_other
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@review, partial: "reviews/form", locals: {review: @review}) }
        format.html do
          flash.now[:error] = "Review not created"
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

  def add_topic
    included_review_ids = params[:included_reviews].split(",").map(&:to_i)
    @assign_topic = Topic.friendly_find(params[:search_assign_topic])
    if @assign_topic.blank?
      flash[:error] = "Unable to find topic: '#{params[:search_assign_topic]}'"
    else
      reviews_updated = 0
      included_reviews = current_user.reviews.where(id: included_review_ids)
      reviews_with_topic = ReviewTopic.where(topic_id: @assign_topic.id, review_id: included_reviews)
      # These are the reviews to add topic to
      included_reviews.where(id: review_ids_selected - reviews_with_topic.pluck(:review_id)).each do |review|
        reviews_updated += 1
        review.add_topic(@assign_topic)
      end
      reviews_with_topic.where.not(review_id: review_ids_selected).each do |review_topic|
        reviews_updated += 1
        review_topic.review.remove_topic(@assign_topic)
      end
      # included_reviews
      if reviews_updated > 0
        flash[:success] = "Added #{@assign}"
      else
        flash[:notice] = "No reviews were updated"
      end
    end
    redirect_back(fallback_location: reviews_path(user: current_user), status: :see_other)
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

  def multi_user_searches
    %w[recent following]
  end

  def viewable_reviews
    if params[:user].blank? || multi_user_searches.include?(params[:user].downcase)
      @viewing_single_user = false
      @can_view_reviews = true
    else
      raise ActiveRecord::RecordNotFound if user_subject.blank?
      @viewing_single_user = true
      @viewing_current_user = user_subject == current_user
      @reviews_private = user_subject.reviews_private
      @can_view_reviews = user_subject.account_public || @viewing_current_user ||
        user_subject.follower_approved?(current_user)
    end
    searched_reviews
  end

  def viewing_display_name
    @viewing_display_name ||= if user_subject.present?
      user_subject.username
    else
      (params[:user] || multi_user_searches.first).downcase
    end
  end

  def searched_reviews
    reviews = if viewing_display_name == "following"
      current_user&.following_reviews_visible || Review.none
    elsif viewing_display_name == "recent"
      Review
    else
      @can_view_reviews ? user_subject.reviews : Review.none
    end

    if current_topics.present?
      reviews = Review.matching_topics(current_topics)
    end

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

  def review_ids_selected
    params.keys.map do |k|
      next unless k.match?(/review_id_\d/)
      k.gsub("review_id_", "")
    end.compact.map(&:to_i)
  end
end
