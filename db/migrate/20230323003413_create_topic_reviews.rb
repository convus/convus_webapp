class CreateTopicReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :topic_reviews do |t|
      t.references :topic
      t.datetime :start_at
      t.datetime :end_at
      t.integer :status
      t.string :topic_name
      t.string :slug

      t.timestamps
    end
  end
end
