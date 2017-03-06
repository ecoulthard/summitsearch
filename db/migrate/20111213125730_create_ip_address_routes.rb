class CreateIpAddressRoutes < ActiveRecord::Migration
  def change
    create_table :ip_address_routes do |t|
      t.integer :ip_address_id, :null => false
      t.integer :route_id, :null => false
      t.integer :visit_count, :default => 0

      t.timestamps
    end
    add_index :ip_address_routes, :ip_address_id
    add_index :ip_address_routes, :route_id
  end
end
