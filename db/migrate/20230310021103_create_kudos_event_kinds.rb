class CreateKudosEventKinds < ActiveRecord::Migration[7.0]
  def change
    create_table :kudos_event_kinds do |t|
      t.string :name
      t.integer :period
      t.integer :max_per_period
      t.integer :total_kudos

      t.timestamps
    end
  end
end
