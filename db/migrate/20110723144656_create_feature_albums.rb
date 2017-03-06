class CreateFeatureAlbums < ActiveRecord::Migration
  def self.up
    create_table :feature_albums do |t|
      t.integer :feature_id, :null => false
      t.integer :album_id, :null => false
      t.boolean :in_title, :default => false
    end
    add_index :feature_albums, :feature_id
    add_index :feature_albums, :album_id
  end

  def self.down
    drop_table :feature_albums
  end
end
