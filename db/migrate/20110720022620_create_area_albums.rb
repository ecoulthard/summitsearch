class CreateAreaAlbums < ActiveRecord::Migration
  def self.up
    create_table :area_albums do |t|
      t.integer :area_id, :null => false
      t.integer :album_id, :null => false
      t.boolean :in_title, :default => false
    end
    add_index :area_albums, :area_id
    add_index :area_albums, :album_id
  end

  def self.down
    drop_table :area_albums
  end
end
