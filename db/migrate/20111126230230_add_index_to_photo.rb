class AddIndexToPhoto < ActiveRecord::Migration
  def change
    add_index :photos, :area_id
    add_index :photos, :route_id
  end
end
