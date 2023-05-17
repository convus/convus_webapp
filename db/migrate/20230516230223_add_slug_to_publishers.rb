class AddSlugToPublishers < ActiveRecord::Migration[7.0]
  def change
    add_column :publishers, :slug, :string
  end
end
