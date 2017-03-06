class AddAlbumIdToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :album_id, :integer
    add_index :photos, :album_id
  end

  def self.down
    remove_column :photos, :album_id
  end
end
