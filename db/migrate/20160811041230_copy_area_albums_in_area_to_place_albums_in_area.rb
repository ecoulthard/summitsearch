class CopyAreaAlbumsInAreaToPlaceAlbumsInArea < ActiveRecord::Migration
  def up
    execute "INSERT INTO place_album_in_areas (place_id,album_id)
     SELECT p.id, aaa.album_id
     FROM area_album_in_areas aaa INNER JOIN places p ON aaa.area_id = p.area_id
"    
  end

  def down
    execute "DELETE FROM place_album_in_areas"
  end
end
