class SetPlaceIdOfRoutes < ActiveRecord::Migration
  def up
    execute "update routes set place_id=places.id
     from places where routes.feature_id=places.feature_id"
  end

  def down
    execute "update routes set place_id=NULL"
  end
end
