class Admin::UsersController < Admin::BaseController
  include TranzitoUtils::SortableTable

  before_action :set_period, only: [:index]
  before_action :find_user, except: [:index]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 25
    @users = searched_users.reorder("users.#{sort_column} #{sort_direction}")
      .includes(:ratings).page(page).per(@per_page)
  end

  def edit
  end

  def update
    if @user.update(permitted_params)
      flash[:success] = "User updated"
      redirect_to edit_admin_user_path(@user), status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "Topic removed"
    redirect_to admin_topics_path, status: :see_other
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

  def permitted_params
    params.require(:user).permit(:username, :role)
  end

  def find_user
    @user = User.friendly_find!(params[:id])
  end
end
