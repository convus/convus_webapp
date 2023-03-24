class CreateTopicReviewVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :topic_review_votes do |t|
      t.references :user
      t.references :topic_review
      t.references :rating
      t.boolean :manual_rank, default: false
      t.integer :vote_score
      t.boolean :recommended, default: false

      t.timestamps
    end
  end
end
