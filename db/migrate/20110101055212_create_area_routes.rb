class CreateAreaRoutes < ActiveRecord::Migration
  def self.up
    create_table :area_routes do |t|
      t.integer :area_id
      t.integer :route_id
    end
    add_index :area_routes, :area_id
    add_index :area_routes, :route_id
  end

  def self.down
    drop_table :area_routes
  end
end
