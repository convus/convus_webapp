class CreateTopicInvestigationVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :topic_investigation_votes do |t|
      t.references :user
      t.references :topic_investigation
      t.references :review
      t.boolean :manual_rank, default: false
      t.integer :listing_order
      t.boolean :recommended, default: false

      t.timestamps
    end
  end
end
