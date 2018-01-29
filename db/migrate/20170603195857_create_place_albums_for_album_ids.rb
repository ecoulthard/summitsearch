class CreatePlaceAlbumsForAlbumIds < ActiveRecord::Migration
  def up
    execute "INSERT INTO place_albums (place_id,album_id,in_title)
     SELECT a.place_id, a.id, true
     FROM albums a
     WHERE a.place_id IS NOT NULL
    "    
  end

  def down
  end
end
