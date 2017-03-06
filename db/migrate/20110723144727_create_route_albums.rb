class CreateRouteAlbums < ActiveRecord::Migration
  def self.up
    create_table :route_albums do |t|
      t.integer :route_id, :null => false
      t.integer :album_id, :null => false
      t.boolean :in_title, :default => false
    end
    add_index :route_albums, :route_id
    add_index :route_albums, :album_id
  end

  def self.down
    drop_table :route_albums
  end
end
