class Admin::PublishersController < Admin::BaseController
  include TranzitoUtils::SortableTable

  before_action :set_period, only: [:index]
  before_action :find_publisher, except: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 500
    @publishers = searched_publishers.reorder("publishers.#{sort_column} #{sort_direction}")
      .includes(:citations).page(page).per(@per_page)
  end

  def show
    redirect_to edit_admin_publisher_path(params[:id])
    nil
  end

  def edit
    @citations = @publisher.citations.reorder(created_at: :desc)
  end

  def update
    if @publisher.update(permitted_params)
      flash[:success] = "Publisher updated"
      redirect_to admin_publishers_path, status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  private

  def sortable_columns
    %w[created_at updated_at domain name]
  end

  def searched_publishers
    publishers = Publisher

    if params[:search_remove_query].present?
      @remove_query = TranzitoUtils::Normalize.boolean(params[:search_remove_query])
      publishers = @remove_query ? publishers.remove_query : publishers.keep_query
    end

    @time_range_column = (sort_column == "updated_at") ? "updated_at" : "created_at"
    publishers.where(@time_range_column => @time_range)
  end

  def permitted_params
    params.require(:publisher).permit(:name, :remove_query, :base_word_count)
  end

  def find_publisher
    @publisher = Publisher.find(params[:id])
  end
end
