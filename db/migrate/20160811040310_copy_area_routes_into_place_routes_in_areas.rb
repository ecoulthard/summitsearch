class CopyAreaRoutesIntoPlaceRoutesInAreas < ActiveRecord::Migration
  def up
    execute "INSERT INTO place_route_in_areas (place_id,route_id)
     SELECT p.id, ar.route_id
     FROM area_routes ar INNER JOIN places p ON ar.area_id = p.area_id"    
  end

  def down
    execute "DELETE FROM place_route_in_areas"
  end
end
