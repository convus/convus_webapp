class CreateKudosEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :kudos_events do |t|
      t.references :event
      t.references :user
      t.references :kudos_event_kind
      t.integer :potential_kudos
      t.integer :total_kudos
      t.date :created_date

      t.timestamps
    end

    add_column :users, :total_kudos, :integer
  end
end
