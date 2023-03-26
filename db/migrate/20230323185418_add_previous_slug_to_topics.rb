class AddPreviousSlugToTopics < ActiveRecord::Migration[7.0]
  def change
    add_column :topics, :previous_slug, :string
  end
end
