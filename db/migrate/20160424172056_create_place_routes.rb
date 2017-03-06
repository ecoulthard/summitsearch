class CreatePlaceRoutes < ActiveRecord::Migration
  def change
    create_table :place_routes do |t|
      t.integer :place_id
      t.integer :route_id
      t.integer :waypoint_index
    end
    add_index :place_routes, :place_id
    add_index :place_routes, :route_id
  end
end
