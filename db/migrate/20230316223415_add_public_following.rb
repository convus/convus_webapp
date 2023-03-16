class AddPublicFollowing < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :following_public, :boolean, default: false
  end
end
