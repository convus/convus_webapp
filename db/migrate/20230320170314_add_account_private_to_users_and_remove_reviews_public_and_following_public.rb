class AddAccountPrivateToUsersAndRemoveReviewsPublicAndFollowingPublic < ActiveRecord::Migration[7.0]
  def change
    add_column :user_followings, :approved, :boolean, default: false
    remove_column :user_followings, :reviews_public, :boolean, default: false

    add_column :users, :account_private, :boolean, default: false
    remove_column :users, :reviews_public, :boolean, default: false
    remove_column :users, :following_public, :boolean, default: false
  end
end
