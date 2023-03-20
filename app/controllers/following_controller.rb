class FollowingController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!
  before_action :find_user

  def add
    user_following = user_following_match.first_or_create
    if user_following.valid?
      flash[:success] = "Following #{@user.username}"
    elsif @user.blank?
      flash[:error] = "Unable to find user: '#{params[:id]}'"
    else
      flash[:error] = "Unable to follow #{@user.username}, #{user_following.errors.full_messages.to_sentence}"
    end
    redirect_back(fallback_location: user_root_url, status: :see_other)
  end

  def approve
    if user_follower&.update(approved: true)
      flash[:success] = "Approved follower: #{@user.username}"
    elsif @user.blank?
      flash[:error] = "Unable to find user: '#{params[:id]}'"
    else
      flash[:error] = "Unable to approve follower: #{@user.username}, #{user_following.errors.full_messages.to_sentence}"
    end
  end

  def unapprove
    if user_follower&.update(approved: false)
      flash[:success] = "Un-approved follower: #{@user.username}"
    elsif @user.blank?
      flash[:error] = "Unable to find user: '#{params[:id]}'"
    else
      flash[:error] = "Unable to un-approve follower: #{@user.username}, #{user_following.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    if @user.blank?
      flash[:error] = "Unable to find user: #{params[:id]}"
    else
      user_following = user_following_match.first
      if user_following.present?
        user_following.destroy
        flash[:success] = "Stopped following #{@user.username}"
      else
        flash[:notice] = "You weren't following #{@user.username}"
      end
    end
    redirect_back(fallback_location: user_root_url, status: :see_other)
  end

  private

  def user_following_match
    UserFollowing.where(user_id: current_user.id, following_id: @user&.id)
  end

  def user_follower
    UserFollowing.where(user_id: @user&.id, following_id: current_user.id)
  end

  def find_user
    @user = User.friendly_find(params[:id])
    return if @user.present?
    raise ActiveRecord::RecordNotFound
  end
end
