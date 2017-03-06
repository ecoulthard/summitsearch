class CreateIpAddressAreas < ActiveRecord::Migration
  def change
    create_table :ip_address_areas do |t|
      t.integer :ip_address_id, :null => false
      t.integer :area_id, :null => false
      t.integer :visit_count, :default => 0

      t.timestamps
    end
    add_index :ip_address_areas, :ip_address_id
    add_index :ip_address_areas, :area_id
  end
end
