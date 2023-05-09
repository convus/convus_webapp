class AddVersionIntegerToRatings < ActiveRecord::Migration[7.0]
  def change
    add_column :ratings, :version_integer, :integer
  end
end
