class AddDistanceIconToWaypoint < ActiveRecord::Migration
  def self.up
    add_column :waypoints, :distance, :decimal, :precision => 5, :scale => 2
    add_column :waypoints, :icon, :string, :limit => 32
  end

  def self.down
    remove_column :waypoints, :icon
    remove_column :waypoints, :distance
  end
end
