class CopyFeatureRoutesIntoPlaceRoutes < ActiveRecord::Migration
  def up
    execute "INSERT INTO place_routes (place_id,route_id,waypoint_index)
     SELECT p.id, fr.route_id, waypoint_index
     FROM feature_routes fr INNER JOIN places p ON fr.feature_id = p.feature_id"    
  end

  def down
    execute "DELETE FROM place_routes"
  end
end
