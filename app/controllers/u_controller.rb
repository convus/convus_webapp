class UController < ApplicationController
  before_action :find_user!
  before_action :ensure_user_is_current_user!, except: %i[show following]
  include TranzitoUtils::SortableTable

  def show
  end

  def following
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @user_followings = @user.user_followings.reorder("user_followings.#{sort_column} #{sort_direction}")
      .includes(:following).page(page).per(@per_page)
  end

  def edit
  end

  def update
    if @user.update(permitted_params)
      flash[:success] = "Account updated"
      redirect_to u_path(@user.to_param), status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  private

  def sortable_columns
    %w[created_at]
  end

  def permitted_params
    params.require(:user).permit(:about, :following_public, :reviews_public, :username)
  end

  def find_user!
    @user = User.friendly_find!(params[:id])
  end

  def ensure_user_is_current_user!
    if current_user.blank?
      redirect_to_signup_unless_user_present!
    elsif current_user != @user
      flash[:error] = "You aren't able to edit that user"
      redirect_to user_root_url && return
    end
  end
end
