class AddDidNotUnderstandToReviews < ActiveRecord::Migration[7.0]
  def change
    add_column :reviews, :did_not_understand, :boolean, default: false
  end
end
