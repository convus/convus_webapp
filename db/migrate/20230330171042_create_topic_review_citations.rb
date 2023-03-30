class CreateTopicReviewCitations < ActiveRecord::Migration[7.0]
  def change
    create_table :topic_review_citations do |t|
      t.references :topic_review
      t.references :citation
      t.references :citation_topic
      t.integer :vote_score
      t.integer :vote_score_manual
      t.integer :rank

      t.string :display_name

      t.timestamps
    end
    add_reference :topic_review_votes, :topic_review_citation
  end
end
