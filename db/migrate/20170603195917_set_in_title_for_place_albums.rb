class SetInTitleForPlaceAlbums < ActiveRecord::Migration
  def up
    execute "UPDATE place_albums SET in_title=true
     FROM places p, albums a
     WHERE in_title=false AND p.id = place_albums.place_id AND a.Id = place_albums.album_id
	AND a.title LIKE '%' || p.name || '%'
    "    
  end

  def down
  end
end
