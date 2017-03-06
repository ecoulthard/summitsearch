class SetNearbyNamesakeId < ActiveRecord::Migration
  def up
    execute "update places set nearby_namesake_id=p.id
     from features f inner join places p on f.nearby_namesake_id = p.feature_id
     where places.feature_id = f.id"
  end

  def down
    execute "update places set nearby_namesake_id=NULL"
  end

end
