class CopyFeaturePhotosAndAreaPhotosToPlacePhotos < ActiveRecord::Migration
  def up
    execute "INSERT INTO place_photos (place_id,photo_id)
     SELECT p.id, fp.photo_id
     FROM feature_photos fp INNER JOIN places p ON fp.feature_id = p.feature_id
     UNION
     SELECT p.id, ap.photo_id
     FROM area_photos ap INNER JOIN places p ON ap.area_id = p.area_id
"    
  end

  def down
    execute "DELETE FROM place_photos"
  end
end
