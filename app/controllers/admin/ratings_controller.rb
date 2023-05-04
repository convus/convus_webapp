class Admin::RatingsController < Admin::BaseController
  include RateSearchable
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_rating, except: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @ratings = searched_ratings(Rating) # in RateSearchable
      .reorder("ratings.#{sort_column} #{sort_direction}")
      .includes(:citation, :topics, :user).page(page).per(@per_page)
  end

  def show
  end

  def destroy
    @rating.destroy
    flash[:success] = "Rating deleted!"
    redirect_to admin_ratings_path
  end

  private

  def sortable_columns
    %w[created_at user_id display_name]
  end

  def find_rating
    @rating = Rating.find(params[:id])
  end
end
