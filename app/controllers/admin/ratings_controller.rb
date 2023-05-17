class Admin::RatingsController < Admin::BaseController
  include RatingSearchable
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_rating, except: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @ratings = admin_searched_ratings
      .includes(:topics, :user).page(page).per(@per_page)
  end

  def show
  end

  def update
    if TranzitoUtils::Normalize.boolean(params[:set_metadata_attributes])
      @rating.set_metadata_attributes!
      UpdateCitationMetadataFromRatingsJob.perform_async(@rating.citation_id)
      flash[:success] = "Rating metadata reprocessed"
    else
      flash[:error] = "Unknown update action!"
    end
    redirect_back(fallback_location: admin_rating_path(@rating.to_param), status: :see_other)
  end

  def destroy
    @rating.destroy
    flash[:success] = "Rating deleted!"
    redirect_to admin_ratings_path
  end

  private

  def sortable_columns
    %w[created_at user_id display_name version_integer meta]
  end

  def admin_searched_ratings
    ratings = searched_ratings(Rating) # in RatingSearchable

    if sort_column == "meta"
      ratings = (sort_direction == "desc") ? ratings.metadata_present : ratings.metadata_blank
    end

    actual_sort_column = (sort_column == "meta") ? "created_at" : sort_column
    ratings
      .reorder("ratings.#{actual_sort_column} #{sort_direction}")
  end

  def find_rating
    @rating = Rating.find(params[:id])
  end
end
