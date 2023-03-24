class RenameReviewsToRatings < ActiveRecord::Migration[7.0]
  def change
    rename_table :review_topics, :rating_topics
    rename_table :reviews, :ratings
    rename_column :rating_topics, :review_id, :rating_id
  end
end
