class CreateTopicRelations < ActiveRecord::Migration[7.0]
  def change
    create_table :topic_relations do |t|
      t.references :parent
      t.references :child

      t.timestamps
    end
  end
end
