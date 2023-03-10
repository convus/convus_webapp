class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.references :user
      t.references :target, polymorphic: true
      t.integer :kind

      t.timestamps
    end
  end
end
