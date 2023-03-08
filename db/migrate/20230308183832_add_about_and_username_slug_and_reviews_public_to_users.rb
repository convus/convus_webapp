class AddAboutAndUsernameSlugAndReviewsPublicToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :about, :text
    add_column :users, :username_slug, :string
    add_column :users, :reviews_public, :boolean, default: false
  end
end
