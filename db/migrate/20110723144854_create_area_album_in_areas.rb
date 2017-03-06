class CreateAreaAlbumInAreas < ActiveRecord::Migration
  def self.up
    create_table :area_album_in_areas do |t|
      t.integer :area_id, :null => false
      t.integer :album_id, :null => false
    end
    add_index :area_album_in_areas, :area_id
    add_index :area_album_in_areas, :album_id
  end

  def self.down
    drop_table :area_album_in_areas
  end
end
