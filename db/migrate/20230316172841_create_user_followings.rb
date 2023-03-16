class CreateUserFollowings < ActiveRecord::Migration[7.0]
  def change
    create_table :user_followings do |t|
      t.references :user
      t.references :following
      t.boolean :reviews_public, default: false

      t.timestamps
    end
  end
end
