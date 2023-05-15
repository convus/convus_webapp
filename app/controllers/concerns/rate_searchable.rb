module RateSearchable
  extend ActiveSupport::Concern

  def searched_ratings(ratings)
    if current_topics.present?
      ratings = ratings.matching_topics(current_topics)
    end
    if current_user.present? && !@viewing_current_user
      @not_rated = TranzitoUtils::Normalize.boolean(params[:search_not_rated])
      if @not_rated
        ratings = ratings.where.not(citation_id: current_user.ratings.pluck(:citation_id))
      end
      @disagree_following = TranzitoUtils::Normalize.boolean(params[:search_disagree_following])
    end
    ratings = ratings.display_name_search(params[:query]) if params[:query].present?
    # Add display for this
    if params[:search_citation_id].present?
      @searched_citation = Citation.friendly_find(params[:search_citation_id])
      ratings = ratings.where(citation_id: @searched_citation.id)
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

    if TranzitoUtils::Normalize.boolean(params[:search_not_finished])
      @search_not_finished = true
      ratings = ratings.not_finished
    end

    @time_range_column = "created_at"
    ratings.where(@time_range_column => @time_range)
  end
end
