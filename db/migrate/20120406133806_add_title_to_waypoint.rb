class AddTitleToWaypoint < ActiveRecord::Migration
  def change
    add_column :waypoints, :title, :string
    add_column :waypoints, :height_gain, :int
    add_column :waypoints, :height_loss, :int
  end
end
