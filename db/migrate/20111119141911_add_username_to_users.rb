class AddUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :username, :string, :limit => 64
    add_index :users, :username, :unique => true
    rename_column :users, :full_name, :realname
  end
end
