class Admin::TopicsController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_topic, except: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @topics = searched_topics.reorder(order_scope_query)
      .includes(:rating_topics).page(page).per(@per_page)
  end

  def show
    redirect_to edit_admin_topic_path(params[:id])
    nil
  end

  def edit
  end

  def update
    if @topic.update(permitted_params)
      flash[:success] = "Topic updated"
      redirect_to admin_topics_path, status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  private

  def sortable_columns
    %w[created_at updated_at name]
  end

  def order_scope_query
    if sort_column == "name"
      # IDK, send is scary, add protection
      raise "Invalid sort_direction" unless %w[asc desc].include?(sort_direction)
      Topic.arel_table["name"].lower.send(sort_direction)
    else
      "topics.#{sort_column} #{sort_direction}"
    end
  end

  def searched_topics
    topics = Topic

    @time_range_column = (sort_column == "updated_at") ? "updated_at" : "created_at"
    topics.where(@time_range_column => @time_range)
  end

  def permitted_params
    params.require(:topic).permit(:name)
  end

  def find_topic
    @topic = Topic.friendly_find(params[:id])
  end
end
