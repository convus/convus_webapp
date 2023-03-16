class CreateUserFollows < ActiveRecord::Migration[7.0]
  def change
    create_table :user_follows do |t|
      t.references :user
      t.references :following
      t.boolean :reviews_public, default: false

      t.timestamps
    end
  end
end
