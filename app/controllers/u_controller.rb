class UController < ApplicationController
  before_action :find_user!
  before_action :ensure_user_is_current_user!, except: %i[show following followers]
  before_action :redirect_unless_approved!, only: %i[following followers]
  include TranzitoUtils::SortableTable

  def show
  end

  def following
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @user_followings = searched_user_followings(@user.user_followings)
      .reorder("user_followings.#{sort_column} #{sort_direction}")
      .includes(:following).page(page).per(@per_page)
  end

  def followers
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @user_followings = searched_user_followings(@user.user_followers)
      .reorder("user_followings.#{sort_column} #{sort_direction}")
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
    params.require(:user).permit(:about, :account_private, :username)
  end

  def find_user!
    @user = User.friendly_find!(params[:id])
    @viewing_current_user = current_user == @user
  end

  def searched_user_followings(user_followings)
    if @viewing_current_user
      if params[:search_approved] == "approved"
        user_followings = user_followings.approved
      elsif params[:search_approved] == "unapproved"
        user_followings = user_followings.unapproved
      end
    else
      user_followings = user_followings.approved
    end
    user_followings
  end

  def ensure_user_is_current_user!
    if current_user.blank?
      redirect_to_signup_unless_user_present!
    elsif current_user != @user
      flash[:error] = "You aren't able to edit that user"
      redirect_to user_root_url && return
    end
  end

  def redirect_unless_approved!
    return true if @user.account_public? || @viewing_current_user
    if current_user.blank?
      flash[:notice] = "User's account is only visible to their followers"
      return redirect_to_signup_unless_user_present!
    end
    if action_name == "following"
      return true if @user.following_approved?(current_user)
    elsif @user.follower_approved?(current_user)
      return true
    end
    flash[:notice] = "User's account is only visible to their followers"
    redirect_back(fallback_location: user_root_url, status: :see_other)
  end
end
