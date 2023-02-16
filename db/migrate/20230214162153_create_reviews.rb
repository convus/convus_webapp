class CreateReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :reviews do |t|
      t.references :user
      t.references :citation
      t.text :submitted_url

      t.integer :agreement
      t.integer :quality
      t.boolean :changed_my_opinion, default: false, null: false

      t.text :inaccuracies
      t.text :comment
      t.text :topics

      t.timestamps
    end
  end
end
