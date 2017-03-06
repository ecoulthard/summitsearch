class SetPlaceIdOfForemTopics < ActiveRecord::Migration
  def up
    execute "update forem_topics set place_id=places.id
     from places where forem_topics.feature_id=places.feature_id;
     update forem_topics set place_id=places.id
     from places where forem_topics.area_id=places.area_id;
"
  end

  def down
    execute "update forem_topics set place_id=NULL"
  end
end
