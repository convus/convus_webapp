class AddAccountPublicToRatings < ActiveRecord::Migration[7.0]
  def change
    add_column :ratings, :account_public, :boolean, default: false
  end
end
