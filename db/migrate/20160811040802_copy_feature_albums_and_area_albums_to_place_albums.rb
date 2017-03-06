class CopyFeatureAlbumsAndAreaAlbumsToPlaceAlbums < ActiveRecord::Migration
  def up
    execute "INSERT INTO place_albums (place_id,album_id)
     SELECT p.id, fa.album_id
     FROM feature_albums fa INNER JOIN places p ON fa.feature_id = p.feature_id
     UNION
     SELECT p.id, aa.album_id
     FROM area_albums aa INNER JOIN places p ON aa.area_id = p.area_id
"    
  end

  def down
    execute "DELETE FROM place_albums"
  end
end
