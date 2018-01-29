class CreatePlacePhotosForPlaceIds < ActiveRecord::Migration
  def up
    execute "INSERT INTO place_photos (place_id,photo_id,in_title)
     SELECT p.place_id, p.id, true
     FROM photos p
     WHERE p.place_id IS NOT NULL
    "    
  end

  def down
  end
end
