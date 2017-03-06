class CreateBorderPoints < ActiveRecord::Migration
  def change
    create_table :border_points do |t|
      t.decimal :latitude, :null => false, :precision => 8, :scale => 6
      t.decimal :longitude, :null => false, :precision => 9, :scale => 6
      t.integer :place_id, :null => false
      t.integer :local_index, :null => false
    end

    add_index :border_points, :place_id

  end
end
