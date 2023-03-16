class FollowersController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  before_action :find_user!

  def create
    # user_follow
    if false
      flash[:success] = "Following #{@user.username}"
    else
      flash[:error] = "Failed to follow #{@user.username}, #{user_following.errors.full_messages.to_sentence}"
    end
    redirect_back(fallback: user_root_url), status: :see_other
  end

  def destroy

  end

  private

  def find_user!
    @user = User.friendly_find!(params[:id])
  end
end
