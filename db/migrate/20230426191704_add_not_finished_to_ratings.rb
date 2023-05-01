class AddNotFinishedToRatings < ActiveRecord::Migration[7.0]
  def change
    add_column :ratings, :not_finished, :boolean, default: false
  end
end
