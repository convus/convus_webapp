class CreateTopicReviewVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :topic_review_votes do |t|
      t.references :user
      t.references :topic_review
      t.references :rating
      t.boolean :manual_score, default: false
      t.integer :vote_score
      t.integer :rank
      t.datetime :rating_at

      t.timestamps
    end
  end
end
