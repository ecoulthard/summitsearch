class SetInTitleForPlacePhotos < ActiveRecord::Migration
  def up
    execute "UPDATE place_photos SET in_title=true
     FROM places p, photos ph
     WHERE in_title=false AND p.id = place_photos.place_id AND ph.Id = place_photos.photo_id
	AND ph.title LIKE '%' || p.name || '%'
    "    
  end

  def down
  end
  
end
