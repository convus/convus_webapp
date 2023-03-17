class Admin::UsersController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @users = searched_users.reorder("users.#{sort_column} #{sort_direction}")
      .includes(:reviews).page(page).per(@per_page)
  end

  private

  def sortable_columns
    %w[created_at updated_at email username]
  end

  def searched_users
    users = User

    users = users.admin_search(params[:query]) if params[:query].present?

    @time_range_column = (sort_column == "updated_at") ? "updated_at" : "created_at"
    users.where(@time_range_column => @time_range)
  end
end
