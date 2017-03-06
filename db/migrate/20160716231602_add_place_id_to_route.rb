class AddPlaceIdToRoute < ActiveRecord::Migration
  def change
    add_column :routes, :place_id, :int
    add_index :routes, :place_id
  end
end
