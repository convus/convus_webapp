class AddTextToCitation < ActiveRecord::Migration[7.0]
  def change
    add_column :citations, :citation_text, :text
  end
end
