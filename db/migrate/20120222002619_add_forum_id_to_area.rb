class AddForumIdToArea < ActiveRecord::Migration
  def change
    add_column :areas, :forum_id, :integer
    add_index :areas, :forum_id
  end
end
