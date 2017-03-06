class SetPlaceIdOfPhotos < ActiveRecord::Migration
  def up
    execute "update photos set place_id=places.id
     from places where photos.feature_id=places.feature_id;
     update photos set place_id=places.id
     from places where photos.area_id=places.area_id;
"
  end

  def down
    execute "update photos set place_id=NULL"
  end
end
