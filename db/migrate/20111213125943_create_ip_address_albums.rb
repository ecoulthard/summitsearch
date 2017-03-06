class CreateIpAddressAlbums < ActiveRecord::Migration
  def change
    create_table :ip_address_albums do |t|
      t.integer :ip_address_id, :null => false
      t.integer :album_id, :null => false
      t.integer :visit_count, :default => 0

      t.timestamps
    end
    add_index :ip_address_albums, :ip_address_id
    add_index :ip_address_albums, :album_id
  end
end
