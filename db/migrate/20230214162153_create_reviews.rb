class CreateReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :reviews do |t|
      t.references :user
      t.references :citation
      t.text :submitted_url
      t.text :citation_title

      t.integer :agreement, default: 0
      t.integer :quality, default: 0
      t.boolean :changed_my_opinion, default: false, null: false

      t.boolean :significant_factual_error
      t.text :error_quotes
      t.text :topics_text

      t.timestamps
    end
  end
end
