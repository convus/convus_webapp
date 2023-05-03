class Admin::CitationsController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_citation, except: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
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
    @citation.manually_updating = true
    if @citation.update(permitted_params)
      @citation.ratings.each { |r| update_citation_rating_topics(@citation, r) }
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
    params.require(:citation).permit(:title, :topics_string, :authors_str, :timezone,
      :published_at_in_zone, :published_updated_at_in_zone, :description, :canonical_url,
      :word_count, :paywall)
  end

  def find_citation
    @citation = Citation.find(params[:id])
  end

  def update_citation_rating_topics(citation, rating)
    # Currently, citation topics are complicated to create backward
    rating.add_topic(citation.reload.topics.pluck(:name))
  end
end
