class Admin::CitationsController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_citation, except: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @citations = searched_citations.reorder("citations.#{sort_column} #{sort_direction}")
      .includes(:ratings, :topics, :quizzes).page(page).per(@per_page)
  end

  def show
    redirect_to edit_admin_citation_path(params[:id])
    nil
  end

  def edit
    @edit_published_date = TranzitoUtils::Normalize.boolean(params[:edit_published_date])
  end

  def update
    if TranzitoUtils::Normalize.boolean(params[:update_citation_metadata_from_ratings])
      # Perform inline, so you see if there is an error
      UpdateCitationMetadataFromRatingsJob.new.perform(@citation.id)
      flash[:success] = "Rating metadata reprocessed"
      redirect_back(fallback_location: edit_admin_citation_path(@citation.id), status: :see_other)
    else
      @citation.manually_updating = true
      if @citation.update(permitted_params)
        @citation.reload
        @citation.ratings.each { |r| update_citation_rating_topics(@citation, r) }
        flash[:success] = "Citation updated"
        redirect_to edit_admin_citation_path(@citation), status: :see_other
      else
        render :edit, status: :see_other
      end
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
    params.require(:citation).permit(:authors_str,
      :canonical_url,
      :citation_text,
      :description,
      :paywall,
      :published_at_in_zone,
      :published_updated_at_in_zone,
      :subject,
      :timezone,
      :title,
      :topics_string,
      :word_count)
  end

  def find_citation
    @citation = Citation.find(params[:id])
  end

  def update_citation_rating_topics(citation, rating)
    # Currently, citation topics are complicated to create backward
    # Force the ratings topics to match the citation topics. See the specs for explanation
    rating.update(topics_text: citation.topics_string("\n"))
  end
end
