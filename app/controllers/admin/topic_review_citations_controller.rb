class Admin::TopicReviewCitationsController < Admin::BaseController
  before_action :find_topic_review_citation

  def edit
    @per_page = params[:per_page] || 50
    @topic_review = @topic_review_citation.topic_review
    @pagy, @topic_review_votes = pagy(@topic_review_citation.topic_review_votes.vote_ordered
      .includes(:user), limit: @per_page)
  end

  def update
    if @topic_review_citation.update(permitted_params)
      flash[:success] = "Review Citation updated"
      redirect_to edit_admin_topic_review_path(@topic_review_citation.topic_review), status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  private

  def permitted_params
    params.require(:topic_review_citation).permit(:vote_score_manual)
  end

  def find_topic_review_citation
    @topic_review_citation = TopicReviewCitation.find(params[:id])
  end
end
