class CreatePublishers < ActiveRecord::Migration[7.0]
  def change
    create_table :publishers do |t|
      t.string :domain
      t.string :name
      t.boolean :remove_query, default: false

      t.timestamps
    end
    add_reference :citations, :publisher
  end
end
