class Admin::TopicReviewCitationsController < Admin::BaseController
  before_action :find_topic_review_citation

  def edit
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @topic_review = @topic_review_citation.topic_review
    @topic_review_votes = @topic_review_citation.topic_review_votes.vote_ordered
      .includes(:user)
      .page(page).per(@per_page)
  end

  def update
    if @topic_review.update(permitted_params)
      flash[:success] = "Review updated"
      redirect_to admin_topic_reviews_path, status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  private

  def permitted_params
    params.require(:topic_review).permit(:topic_name, :timezone, :start_at_in_zone, :end_at_in_zone)
  end

  def find_topic_review_citation
    @topic_review_citation = TopicReviewCitation.find(params[:id])
  end
end
