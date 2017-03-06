class CreatePlaceAlbumInAreas < ActiveRecord::Migration
  def change
    create_table :place_album_in_areas do |t|
      t.integer :place_id, :null => false
      t.integer :album_id, :null => false
    end
    add_index :place_album_in_areas, :place_id
    add_index :place_album_in_areas, :album_id
  end
end
