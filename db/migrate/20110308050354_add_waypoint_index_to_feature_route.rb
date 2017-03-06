class AddWaypointIndexToFeatureRoute < ActiveRecord::Migration
  def self.up
    add_column :feature_routes, :waypoint_index, :integer
  end

  def self.down
    remove_column :feature_routes, :waypoint_index
  end
end
