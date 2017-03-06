class SetPlaceIdOfAscents < ActiveRecord::Migration
  def up
    execute "update ascents set place_id=places.id
     from places where ascents.feature_id=places.feature_id"
  end

  def down
    execute "update ascents set place_id=NULL"
  end
end
