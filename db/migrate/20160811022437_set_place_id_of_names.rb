class SetPlaceIdOfNames < ActiveRecord::Migration
  def up
    execute "update names set place_id=places.id
     from places where names.feature_id=places.feature_id;
     update names set place_id=places.id
     from places where names.area_id=places.area_id;
"
  end

  def down
    execute "update names set place_id=NULL"
  end
end
