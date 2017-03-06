class AddNearbyNamesakeToFeature < ActiveRecord::Migration
  def change
    add_column :features, :nearby_namesake_id, :int
  end
end
