class LandingController < ApplicationController
  helper_method :viewable_ratings

  def index
    @page_title = "Convus"
    @ratings = Rating.joins(:citation, :user).reorder("ratings.created_at desc").limit(5)

    @quizzes = Quiz.joins(:citation).active.citation_ordered.limit(5)
    if current_user.present?
      @quiz_response_finished_ids = current_user.quiz_responses.finished.where(quiz_id: @quizzes.pluck(:id)).pluck(:quiz_id)
      @quiz_response_in_progress_ids = current_user.quiz_responses.in_progress.where(quiz_id: @quizzes.pluck(:id)).pluck(:quiz_id)
    end
  end

  def about
  end

  def privacy
  end

  def browser_extensions
  end

  def browser_extension_auth
    redirect_to_signup_unless_user_present!
    @render_api_token = true
    @skip_ga = true # Skip Google analytics, this is a private page
  end

  def support
  end

  private

  def viewable_ratings
    @viewable_ratings ||= Rating.joins(:citation)
  end
end
