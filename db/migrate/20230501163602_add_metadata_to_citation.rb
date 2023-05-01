class AddMetadataToCitation < ActiveRecord::Migration[7.0]
  def change
    add_column :citations, :authors, :jsonb
    add_column :citations, :published_at, :datetime
    add_column :citations, :published_updated_at, :datetime
    add_column :citations, :description, :text
    add_column :citations, :canonical_url, :text
    add_column :citations, :word_count, :integer
    add_column :citations, :paywall, :boolean, default: false
    # Other, non-citation things here
    add_column :publishers, :base_word_count, :integer
    add_column :ratings, :metadata_at, :datetime
  end
end
