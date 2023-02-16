class CreateCitations < ActiveRecord::Migration[7.0]
  def change
    create_table :citations do |t|
      t.text :url
      t.text :title

      t.jsonb :url_components

      t.timestamps
    end
  end
end
