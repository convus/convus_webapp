class AddApiTokenToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :api_token, :text
  end
end
