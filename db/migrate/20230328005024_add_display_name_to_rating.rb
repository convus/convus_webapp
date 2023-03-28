class AddDisplayNameToRating < ActiveRecord::Migration[7.0]
  def change
    add_column :ratings, :display_name, :text
  end
end
