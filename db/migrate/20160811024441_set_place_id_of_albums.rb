class SetPlaceIdOfAlbums < ActiveRecord::Migration
  def up
    execute "update albums set place_id=places.id
     from places where albums.feature_id=places.feature_id;
     update albums set place_id=places.id
     from places where albums.area_id=places.area_id;
"
  end

  def down
    execute "update albums set place_id=NULL"
  end
end
