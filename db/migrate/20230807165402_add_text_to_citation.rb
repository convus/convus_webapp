class AddTextToCitation < ActiveRecord::Migration[7.0]
  def change
    add_column :citations, :text, :text
  end
end
