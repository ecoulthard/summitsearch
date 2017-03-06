class CreateIpAddressPhotos < ActiveRecord::Migration
  def change
    create_table :ip_address_photos do |t|
      t.integer :ip_address_id, :null => false
      t.integer :photo_id, :null => false
      t.integer :visit_count, :default => 0

      t.timestamps
    end
    add_index :ip_address_photos, :ip_address_id
    add_index :ip_address_photos, :photo_id
  end
end
