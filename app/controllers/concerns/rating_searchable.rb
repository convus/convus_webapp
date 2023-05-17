module RatingSearchable
  extend ActiveSupport::Concern

  def searched_ratings(ratings)
    ratings = ratings.joins(:citation)
    if current_user.present? && !viewing_current_user?
      @not_rated = TranzitoUtils::Normalize.boolean(p_params[:search_not_rated])
      if @not_rated
        ratings = ratings.where.not(citation_id: current_user.ratings.pluck(:citation_id))
      end
      @disagree_following = TranzitoUtils::Normalize.boolean(p_params[:search_disagree_following])
    end
    ratings = ratings.display_name_search(p_params[:query]) if p_params[:query].present?
    ratings = boolean_searches(ratings)
    ratings = citation_searches(ratings)

    @time_range_column = "created_at"
    ratings.where(@time_range_column => @time_range)
  end

  private

  def p_params
    params.permit(:query, :search_agree, :search_changed_opinion, :search_citation_id,
      :search_disagree, :search_disagree_following, :search_learned_something,
      :search_not_finished, :search_not_rated, :search_not_understood, :search_quality_high,
      :search_quality_low, :search_significant_factual_error)
  end

  def citation_searches(ratings)
    if p_params[:search_citation_id].present?
      @searched_citation = Citation.friendly_find(p_params[:search_citation_id])
      ratings = ratings.where(citation_id: @searched_citation.id)
    end
    if current_topics.present?
      ratings = ratings.merge(Citation.matching_topics(current_topics.map(&:id)))
    end
    if params[:search_publisher].present?
      @publisher = Publisher.friendly_find(params[:search_publisher])
      ratings = ratings.merge(Citation.where(publisher_id: @publisher.id)) if @publisher.present?
    end
    if params[:search_author].present?
      @author = params[:search_author]
      ratings = ratings.merge(Citation.search_author(@author))
    end
    if current_user.present? && !viewing_current_user?
      @not_rated = TranzitoUtils::Normalize.boolean(p_params[:search_not_rated])
      if @not_rated
        ratings = ratings.where.not(citation_id: current_user.ratings.pluck(:citation_id))
      end
    end
    ratings
  end

  def boolean_searches(ratings)
    if TranzitoUtils::Normalize.boolean(p_params[:search_disagree])
      @search_agreement = "disagree"
      ratings = ratings.disagree
    elsif TranzitoUtils::Normalize.boolean(p_params[:search_agree])
      @search_agreement = "agree"
      ratings = ratings.agree
    end

    if TranzitoUtils::Normalize.boolean(p_params[:search_quality_low])
      @search_quality = "low"
      ratings = ratings.quality_low
    elsif TranzitoUtils::Normalize.boolean(p_params[:search_quality_high])
      @search_quality = "high"
      ratings = ratings.quality_high
    end

    if TranzitoUtils::Normalize.boolean(p_params[:search_learned_something])
      @search_learned_something = true
      ratings = ratings.learned_something
    end
    if TranzitoUtils::Normalize.boolean(p_params[:search_changed_opinion])
      @search_changed_opinion = true
      ratings = ratings.changed_opinion
    end

    if TranzitoUtils::Normalize.boolean(p_params[:search_significant_factual_error])
      @search_significant_factual_error = true
      ratings = ratings.significant_factual_error
    end

    if TranzitoUtils::Normalize.boolean(p_params[:search_not_understood])
      @search_not_understood = true
      ratings = ratings.not_understood
    end

    if TranzitoUtils::Normalize.boolean(p_params[:search_not_finished])
      @search_not_finished = true
      ratings = ratings.not_finished
    end
    ratings
  end
end
