class AddFieldsToRoute < ActiveRecord::Migration
  def change
    #change_column :routes, :difficulty, :int
    add_column :routes, :road_id, :int
    add_column :routes, :descent_route_id, :int
    add_column :routes, :access, :string
    add_column :routes, :different_start_end, :boolean, :default => false, :null => false
    add_column :routes, :newb, :boolean, :default => false, :null => false
    add_column :routes, :avalanche_rating, :string
    add_column :routes, :glacier_travel, :boolean, :default => false, :null => false
    add_column :routes, :objective_hazard, :string
    add_column :routes, :seracs, :boolean, :default => false, :null => false
    add_column :routes, :rockfall, :boolean, :default => false, :null => false
    add_column :routes, :river_crossing, :boolean, :default => false, :null => false
  end
end
