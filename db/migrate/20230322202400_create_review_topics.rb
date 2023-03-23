class CreateReviewTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :review_topics do |t|
      t.references :review
      t.references :topic

      t.timestamps
    end
  end
end
