class Admin::CitationsController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_citation, except: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @citations = searched_citations.reorder("citations.#{sort_column} #{sort_direction}")
      .includes(:ratings, :topics).page(page).per(@per_page)
  end

  def show
    redirect_to edit_admin_citation_path(params[:id])
    nil
  end

  def edit
  end

  def update
    if @citation.update(permitted_params)
      flash[:success] = "Citation updated"
      redirect_to admin_citations_path, status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  private

  def sortable_columns
    %w[created_at updated_at title]
  end

  def searched_citations
    citations = Citation

    @time_range_column = (sort_column == "updated_at") ? "updated_at" : "created_at"
    citations.where(@time_range_column => @time_range)
  end

  def permitted_params
    params.require(:citation).permit(:title, :topics_string)
  end

  def find_citation
    @citation = Citation.find(params[:id])
  end
end
