class RatingsController < ApplicationController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: %i[index] # Actually, will want to set after assigning via
  before_action :redirect_to_signup_unless_user_present!, except: %i[new index]
  before_action :find_and_authorize_rating, only: %i[edit update destroy]
  helper_method :viewing_display_name

  def index
    if current_user.blank?
      if params[:user] == "current_user" || viewing_display_name == "following"
        redirect_to_signup_unless_user_present!
        return
      end
    end
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @ratings = viewable_ratings.reorder(order_scope_query)
      .includes(:citation, :user).page(page).per(@per_page)

    @viewing_primary_topic = current_topics.present? && current_topics.pluck(:id) == [primary_topic_review&.id]
    set_rating_assigment_if_passed if @viewing_current_user
    @action_display_name = viewing_display_name.titleize
  end

  def new
    @source = params[:source].presence || "web"
    @no_layout = @source != "web"
    @rating ||= Rating.new(source: @source)
    if @source == "web"
      redirect_to_signup_unless_user_present!
    elsif @source == "turbo_stream"
      render layout: false
    end
  end

  def create
    @rating = Rating.new(permitted_create_params)
    @rating.user = current_user
    if @rating.save
      respond_to do |format|
        format.html do
          flash[:success] = "Rating added"
          redirect_source = (@rating.source == "web") ? nil : @rating.source
          redirect_to new_rating_path(source: redirect_source), status: :see_other
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@rating, partial: "ratings/form", locals: {rating: @rating}) }
        format.html do
          flash.now[:error] = "Rating not created"
          render :new
        end
      end
    end
  end

  def edit
  end

  def update
    if @rating.update(permitted_params)
      flash[:success] = "Rating updated"
      redirect_back(fallback_location: ratings_path(user: current_user), status: :see_other)
    else
      render :edit
    end
  end

  def add_topic
    set_rating_assigment_if_passed
    if @assign_topics.blank?
      flash[:error] = "Unable to find topic: \"#{params[:search_topics] || " "}\""
    else
      included_rating_ids = params[:included_ratings].split(",").map(&:to_i)
      included_ratings = current_user.ratings.where(id: included_rating_ids)
      ratings_updated = @assign_topics.map { |t| update_ratings_with_topic(t, included_ratings) }
      if ratings_updated.sum > 0
        flash[:success] = "Added ratings to #{@assign_topics.map(&:name).join(", ")}"
      else
        flash[:notice] = "No ratings were updated"
      end
    end
    redirect_back(fallback_location: ratings_path(user: current_user), status: :see_other)
  end

  def destroy
    if @rating.destroy
      flash[:success] = "Rating deleted"
      redirect_to ratings_path, status: :see_other
    else
      flash[:error] = "Unable to delete rating!"
      redirect_to edit_rating_path(@rating), status: :see_other
    end
  end

  private

  def permitted_params
    params.require(:rating).permit(*permitted_attrs)
  end

  def permitted_create_params
    params.require(:rating).permit(*(permitted_attrs + [:timezone]))
  end

  def permitted_attrs
    %i[agreement changed_opinion citation_title not_understood
      error_quotes learned_something quality significant_factual_error
      source submitted_url topics_text]
  end

  def sortable_columns
    %w[created_at display_name]
  end

  def multi_user_searches
    %w[all following]
  end

  def viewable_ratings
    if params[:user].blank? || multi_user_searches.include?(params[:user].downcase)
      @viewing_single_user = false
      @can_view_ratings = true
    else
      raise ActiveRecord::RecordNotFound if user_subject.blank?
      @viewing_single_user = true
      @viewing_current_user = user_subject == current_user
      @ratings_private = user_subject.ratings_private
      @can_view_ratings = user_subject.account_public || @viewing_current_user ||
        user_subject.follower_approved?(current_user)
    end
    searched_ratings
  end

  def viewing_display_name
    return @viewing_display_name if defined?(@viewing_display_name)
    @viewing_display_name ||= if user_subject.present?
      user_subject.username
    else
      (params[:user] || multi_user_searches.first).downcase
    end
  end

  def order_scope_query
    if sort_column == "display_name"
      # IDK, send is scary, add protection
      raise "Invalid sort_direction" unless %w[asc desc].include?(sort_direction)
      Rating.arel_table["display_name"].lower.send(sort_direction)
    else
      "ratings.#{sort_column} #{sort_direction}"
    end
  end

  def searched_ratings
    ratings = if viewing_display_name == "following"
      current_user&.following_ratings_visible || Rating.none
    elsif viewing_display_name == "all"
      Rating.where.not(user_id: current_user&.id)
    else
      @can_view_ratings ? user_subject.ratings : Rating.none
    end

    if current_topics.present?
      ratings = ratings.matching_topics(current_topics)
    end
    if current_user.present? && TranzitoUtils::Normalize.boolean(params[:search_not_rated])
      ratings = ratings.where.not(citation_id: current_user.ratings.pluck(:citation_id))
    end

    if TranzitoUtils::Normalize.boolean(params[:search_disagree])
      @search_agreement = "disagree"
      ratings = ratings.disagree
    elsif TranzitoUtils::Normalize.boolean(params[:search_agree])
      @search_agreement = "agree"
      ratings = ratings.agree
    end

    if TranzitoUtils::Normalize.boolean(params[:search_quality_low])
      @search_quality = "low"
      ratings = ratings.quality_low
    elsif TranzitoUtils::Normalize.boolean(params[:search_quality_high])
      @search_quality = "high"
      ratings = ratings.quality_high
    end

    if TranzitoUtils::Normalize.boolean(params[:search_learned_something])
      @search_learned_something = true
      ratings = ratings.learned_something
    end
    if TranzitoUtils::Normalize.boolean(params[:search_changed_opinion])
      @search_changed_opinion = true
      ratings = ratings.changed_opinion
    end

    if TranzitoUtils::Normalize.boolean(params[:search_significant_factual_error])
      @search_significant_factual_error = true
      ratings = ratings.significant_factual_error
    end

    if TranzitoUtils::Normalize.boolean(params[:search_not_understood])
      @search_not_understood = true
      ratings = ratings.not_understood
    end

    @time_range_column = "created_at"
    ratings.where(@time_range_column => @time_range)
  end

  def set_rating_assigment_if_passed
    if TranzitoUtils::Normalize.boolean(params[:search_assign_topic_primary])
      return unless primary_topic_review.present?
      @assigning = true
      @assign_topics = [primary_topic_review.topic]
    elsif params[:search_assign_topic].present?
      topic = Topic.friendly_find(params[:search_assign_topic])
      return unless topic.present?
      @assign_topics = [topic]
      @assigning = true
    elsif current_topics.present?
      @assigning = true
      @assign_topics = current_topics
    end
  end

  def update_ratings_with_topic(topic, included_ratings)
    ratings_updated = 0
    ratings_with_topic = RatingTopic.where(topic_id: topic.id, rating_id: included_ratings)
    # These are the ratings to add topic to
    included_ratings.where(id: rating_ids_selected - ratings_with_topic.pluck(:rating_id)).each do |rating|
      ratings_updated += 1
      rating.add_topic(topic)
    end
    ratings_with_topic.where.not(rating_id: rating_ids_selected).each do |rating_topic|
      ratings_updated += 1
      rating_topic.rating.remove_topic(topic)
    end
    ratings_updated
  end

  def find_and_authorize_rating
    rating = current_user.ratings.where(id: params[:id]).first
    if rating.present?
      @rating = rating
    else
      flash[:error] = "Unable to find that rating"
      redirect_to(user_root_url) && return
    end
  end

  def rating_ids_selected
    params.keys.map do |k|
      next unless k.match?(/rating_id_\d/)
      k.gsub("rating_id_", "")
    end.compact.map(&:to_i)
  end
end
