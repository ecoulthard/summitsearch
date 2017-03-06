class CreatePlaceAlbums < ActiveRecord::Migration
  def change
    create_table :place_albums do |t|
      t.integer :place_id, :null => false
      t.integer :album_id, :null => false
      t.boolean :in_title, :default => false
    end
    add_index :place_albums, :place_id
    add_index :place_albums, :album_id
  end
end
