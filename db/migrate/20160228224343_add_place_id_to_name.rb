class AddPlaceIdToName < ActiveRecord::Migration
  def change
    add_column :names, :place_id, :int
    add_index :names, :place_id
  end
end
