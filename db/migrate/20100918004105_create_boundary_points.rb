class CreateBoundaryPoints < ActiveRecord::Migration
  def self.up
    create_table :boundary_points do |t|
      t.decimal :latitude, :null => false, :precision => 8, :scale => 6
      t.decimal :longitude, :null => false, :precision => 9, :scale => 6
      t.integer :area_id, :null => false
      t.integer :local_index, :null => false

      t.timestamps
    end
    add_index :boundary_points, :area_id

  end

  def self.down
    drop_table :boundary_points
  end
end
