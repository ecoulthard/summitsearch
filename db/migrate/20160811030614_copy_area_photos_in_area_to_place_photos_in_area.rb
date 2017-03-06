class CopyAreaPhotosInAreaToPlacePhotosInArea < ActiveRecord::Migration
  def up
    execute "INSERT INTO place_photo_in_areas (place_id,photo_id)
     SELECT p.id, apa.photo_id
     FROM area_photo_in_areas apa INNER JOIN places p ON apa.area_id = p.area_id
"    
  end

  def down
    execute "DELETE FROM place_photo_in_areas"
  end
end
