class AddPlaceIdToAlbums < ActiveRecord::Migration
  def change
    add_column :albums, :place_id, :int
    add_index :albums, :place_id
  end
end
