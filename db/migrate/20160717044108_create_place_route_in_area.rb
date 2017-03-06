class CreatePlaceRouteInArea < ActiveRecord::Migration
  def change
    create_table :place_route_in_areas do |t|
      t.integer :place_id
      t.integer :route_id
    end
    add_index :place_route_in_areas, :place_id
    add_index :place_route_in_areas, :route_id
  end
end
