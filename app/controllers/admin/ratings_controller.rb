class Admin::RatingsController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_rating, except: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @ratings = searched_ratings.reorder("ratings.#{sort_column} #{sort_direction}")
      .includes(:citation, :topics).page(page).per(@per_page)
  end

  def show
  end

  private

  def sortable_columns
    %w[created_at user_id display_name]
  end

  def searched_ratings
    ratings = Rating
    if current_topics.present?
      ratings = ratings.matching_topics(current_topics)
    end

    ratings = ratings.where(user_id: user_subject.id) if user_subject.present?

    ratings = ratings.display_name_search(params[:query]) if params[:query].present?

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

    @time_range_column = (sort_column == "updated_at") ? "updated_at" : "created_at"
    ratings.where(@time_range_column => @time_range)
  end

  def find_rating
    @rating = Rating.find_by_id(params[:id])
  end
end
