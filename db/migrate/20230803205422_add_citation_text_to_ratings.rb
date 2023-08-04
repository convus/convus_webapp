class AddCitationTextToRatings < ActiveRecord::Migration[7.0]
  def change
    add_column :ratings, :citation_text, :text
  end
end
