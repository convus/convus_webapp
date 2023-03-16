class FollowingController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  before_action :find_user

  def add
    user_following = UserFollowing.where(user_id: current_user.id, following_id: @user&.id)
      .first_or_create
    if user_following.valid?
      flash.now[:success] = "Following #{@user.username}"
    elsif @user.blank?
      flash.now[:error] = "Unable to find user: '#{params[:id]}'"
    else
      flash.now[:error] = "Unable to follow #{@user.username}, #{user_following.errors.full_messages.to_sentence}"
    end
    redirect_back(fallback_location: user_root_url, status: :see_other)
  end

  def destroy

  end

  private

  def find_user
    @user = User.friendly_find(params[:id])
  end
end
