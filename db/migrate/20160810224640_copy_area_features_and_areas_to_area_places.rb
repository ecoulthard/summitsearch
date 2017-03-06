class CopyAreaFeaturesAndAreasToAreaPlaces < ActiveRecord::Migration
  def up
    execute "INSERT INTO area_places (area_id,place_id)
     SELECT a.id, p.id
     FROM area_features af INNER JOIN places a ON af.area_id = a.area_id
                           INNER JOIN places p ON af.feature_id = p.feature_id
     UNION
     SELECT a.id, p.id
     FROM area_areas aa INNER JOIN places a ON aa.parent_area_id = a.area_id
                        INNER JOIN places p ON aa.child_area_id = p.area_id"    
  end

  def down
    execute "DELETE FROM area_places"
  end
end
