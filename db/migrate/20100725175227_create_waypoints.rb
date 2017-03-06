class CreateWaypoints < ActiveRecord::Migration
  def self.up
    create_table :waypoints do |t|
      t.decimal :latitude, :null => false, :precision => 8, :scale => 6
      t.decimal :longitude, :null => false, :precision => 9, :scale => 6
      t.integer :height
      t.string :location
      t.string :difficulty, :limit => 32
      t.text :description, :limit => 512
      t.integer :route_id, :null => false
      t.integer :parent_index
      t.integer :local_index, :null => false #Index in the route

      t.timestamps
    end
    add_index :waypoints, :route_id
  end

  def self.down
    drop_table :waypoints
  end
end
