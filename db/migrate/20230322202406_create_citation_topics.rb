class CreateCitationTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :citation_topics do |t|
      t.references :citation
      t.references :topic
      t.boolean :orphaned, default: false

      t.timestamps
    end
  end
end
