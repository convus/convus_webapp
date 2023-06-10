class AddDisplayNameToTopicReviews < ActiveRecord::Migration[7.0]
  def change
    add_column :topic_reviews, :display_name, :text
  end
end
