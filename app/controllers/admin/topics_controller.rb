class Admin::TopicsController < Admin::BaseController
  include TranzitoUtils::SortableTable

  before_action :set_period, only: [:index]
  before_action :find_topic, except: [:index, :new, :create]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 200
    @topics = searched_topics.reorder("topics.#{sort_column} #{sort_direction}")
      .includes(:rating_topics).page(page).per(@per_page)
  end

  def show
    redirect_to edit_admin_topic_path(params[:id])
    nil
  end

  def new
    @topic ||= Topic.new
  end

  def create
    @topic = Topic.new(permitted_params)
    if @topic.save
      flash[:success] = "Topic created"
      redirect_to admin_topics_path, status: :see_other
    else
      render :new, status: :see_other
    end
  end

  def edit
  end

  def update
    if @topic.update(permitted_params)
      flash[:success] = "Topic updated"
      redirect_to edit_admin_topic_path(@topic), status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  def destroy
    @topic.destroy
    flash[:success] = "Topic removed"
    redirect_to admin_topics_path, status: :see_other
  end

  private

  def sortable_columns
    %w[created_at slug updated_at previous_slug]
  end

  def searched_topics
    topics = Topic

    topics = topics.admin_search(params[:query]) if params[:query].present?

    @time_range_column = (sort_column == "updated_at") ? "updated_at" : "created_at"
    topics.where(@time_range_column => @time_range)
  end

  def permitted_params
    params.require(:topic).permit(:name, :parents_string, :previous_slug)
  end

  def find_topic
    @topic = Topic.friendly_find!(params[:id])
  end
end
