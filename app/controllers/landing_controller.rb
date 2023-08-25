class LandingController < ApplicationController
  helper_method :viewable_ratings

  def index
    @page_title = "Convus"
    @quizzes = Quiz.joins(:citation).reorder("quizzes.created_at desc").limit(5)
    @quiz_response_quiz_ids = current_user&.quiz_responses&.pluck(:quiz_id) || []
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
