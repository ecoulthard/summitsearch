class CreateMountainDetails < ActiveRecord::Migration
  def change
    create_table :mountain_details do |t|
      t.integer :mountain_id
      t.integer :parent_mountain_id
      t.decimal :dist_to_parent, :precision => 19, :scale => 10
      t.decimal :height_and_isolation, :precision => 28, :scale => 10
      t.integer :prominence
      t.decimal :average_slope, :precision => 28, :scale => 10
      t.decimal :steepest_slope, :precision => 28, :scale => 10
      t.decimal :border_latitude_steepest_slope, :precision => 8, :scale => 6
      t.decimal :border_longitude_steepest_slope, :precision => 9, :scale => 6
    end
  end
end
