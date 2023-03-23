class Admin::TopicsController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @topics = searched_topics.reorder(order_scope_query)
      .includes(:review_topics).page(page).per(@per_page)
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
end
