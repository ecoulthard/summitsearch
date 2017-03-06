class AddFeatureIdAreaIdToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :feature_id, :int
    add_column :places, :area_id, :int
    add_index :places, :feature_id
    add_index :places, :area_id
  end
end
