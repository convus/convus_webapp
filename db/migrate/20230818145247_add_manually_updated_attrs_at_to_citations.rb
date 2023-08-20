class AddManuallyUpdatedAttrsAtToCitations < ActiveRecord::Migration[7.0]
  def change
    add_column :citations, :manually_updated_at, :datetime
  end
end
