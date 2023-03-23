class CreateTopicInvestigations < ActiveRecord::Migration[7.0]
  def change
    create_table :topic_investigations do |t|
      t.references :topic
      t.datetime :start_at
      t.datetime :end_at
      t.integer :status

      t.timestamps
    end
  end
end
