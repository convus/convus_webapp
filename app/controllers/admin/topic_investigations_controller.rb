class Admin::TopicInvestigationsController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_topic_investigation, only: %i[edit update destroy]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @topic_investigations = searched_topic_investigations.reorder(order_scope_query)
      .includes(:topic, :topic_investigation_votes).page(page).per(@per_page)
  end

  def new
    @topic_investigation = TopicInvestigation.new
  end

  def create
    @topic_investigation = TopicInvestigation.new(permitted_params)
    if @topic_investigation.save
      flash[:success] = "Investigation created"
      redirect_to admin_topic_investigations_path, status: :see_other
    else
      render :new, status: :see_other
    end
  end

  def edit
  end

  def update
    if @topic_investigation.update(permitted_params)
      flash[:success] = "Investigation updated"
      redirect_to admin_topic_investigations_path, status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  def destroy
    if @topic_investigation.destroy
      flash[:success] = "Topic investigation deleted"
    else
      flash[:error] = "Unable to delete Topic Investigation!"
    end
    redirect_back(fallback_location: admin_topic_investigations_path, status: :see_other)
  end

  private

  def sortable_columns
    %w[created_at updated_at topic_name start_at end_at]
  end

  def order_scope_query
    if sort_column == "name"
      # IDK, send is scary, add protection
      raise "Invalid sort_direction" unless %w[asc desc].include?(sort_direction)
      TopicInvestigation.arel_table["topic_name"].lower.send(sort_direction)
    else
      "topic_investigations.#{sort_column} #{sort_direction}"
    end
  end

  def searched_topic_investigations
    topic_investigations = TopicInvestigation

    time_columns = %w[updated_at start_at end_at]
    @time_range_column = time_columns.include?(sort_column) ? sort_column : "created_at"
    topic_investigations.where(@time_range_column => @time_range)
  end

  def permitted_params
    params.require(:topic_investigation).permit(:topic_name, :timezone, :start_at_in_zone, :end_at_in_zone)
  end

  def find_topic_investigation
    @topic_investigation = TopicInvestigation.find(params[:id])
  end
end
