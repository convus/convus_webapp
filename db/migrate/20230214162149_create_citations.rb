class CreateCitations < ActiveRecord::Migration[7.0]
  def change
    create_table :citations do |t|

      t.timestamps
    end
  end
end
