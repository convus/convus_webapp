class AddTimezoneAndDateToReviews < ActiveRecord::Migration[7.0]
  def change
    add_column :reviews, :timezone, :string
    add_column :reviews, :created_date, :date
  end
end
