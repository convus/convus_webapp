class AddPublishedUpdatedAtWithFallback < ActiveRecord::Migration[7.0]
  def change
    add_column :citations, :published_updated_at_with_fallback, :datetime
    add_index :citations, :published_updated_at_with_fallback
  end
end
