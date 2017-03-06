class AddPlaceIdToAscent < ActiveRecord::Migration
  def change
    add_column :ascents, :place_id, :int
    add_index :ascents, :place_id
  end
end
