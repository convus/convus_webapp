class Admin::TopicReviewsController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_topic_review, only: %i[edit update destroy]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @topic_reviews = searched_topic_reviews.reorder(order_scope_query)
      .includes(:topic, :topic_review_votes).page(page).per(@per_page)
  end

  def new
    @topic_review = TopicReview.new
  end

  def create
    @topic_review = TopicReview.new(permitted_params)
    if @topic_review.save
      flash[:success] = "Review created"
      redirect_to admin_topic_reviews_path, status: :see_other
    else
      render :new, status: :see_other
    end
  end

  def edit
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @topic_review_citations = @topic_review.topic_review_citations.vote_ordered
      .includes(:topic_review_votes, :citation)
      .page(page).per(@per_page)
    @topic_review_votes = searched_topic_review_votes
      .includes(:rating, :user)
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

  def destroy
    if @topic_review.destroy
      flash[:success] = "Topic review deleted"
    else
      flash[:error] = "Unable to delete Topic review!"
    end
    redirect_back(fallback_location: admin_topic_reviews_path, status: :see_other)
  end

  private

  def sortable_columns
    %w[created_at updated_at topic_name start_at end_at]
  end

  def order_scope_query
    if sort_column == "name"
      # IDK, send is scary, add protection
      raise "Invalid sort_direction" unless %w[asc desc].include?(sort_direction)
      TopicReview.arel_table["topic_name"].lower.send(sort_direction)
    else
      "topic_reviews.#{sort_column} #{sort_direction}"
    end
  end

  def searched_topic_reviews
    topic_reviews = TopicReview

    time_columns = %w[updated_at start_at end_at]
    @time_range_column = time_columns.include?(sort_column) ? sort_column : "created_at"
    topic_reviews.where(@time_range_column => @time_range)
  end

  def searched_topic_review_votes
    topic_review_votes = @topic_review.topic_review_votes.vote_ordered
    if user_subject.present?
      topic_review_votes = topic_review_votes.where(user_id: user_subject.id)
    end
    topic_review_votes
  end

  def permitted_params
    params.require(:topic_review).permit(:topic_name, :timezone, :display_name,
      :start_at_in_zone, :end_at_in_zone)
  end

  def find_topic_review
    @topic_review = TopicReview.find(params[:id])
  end
end
