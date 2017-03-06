class CreateUserAlbums < ActiveRecord::Migration
  def self.up
    create_table :user_albums do |t|
      t.integer :user_id, :null => false
      t.integer :album_id, :null => false
      t.integer :visit_count, :default => 0
      t.integer :rating, :limit => 3

      t.timestamps
    end
    add_index :user_albums, :user_id
    add_index :user_albums, :album_id
  end

  def self.down
    drop_table :user_albums
  end
end
