class AddSourceToReviews < ActiveRecord::Migration[7.0]
  def change
    add_column :reviews, :source, :string
  end
end
