class AddTopicIdToAlbum < ActiveRecord::Migration
  def change
    add_column :albums, :topic_id, :integer
    add_index :albums, :topic_id
  end
end
