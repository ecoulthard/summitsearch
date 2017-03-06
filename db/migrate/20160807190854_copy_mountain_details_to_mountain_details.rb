class CopyMountainDetailsToMountainDetails < ActiveRecord::Migration
  def up
    execute "insert into mountain_details (mountain_id,parent_mountain_id,dist_to_parent,height_and_isolation)
             select p.id,pm.id,f.dist_to_parent,f.computed_value1
             from features f inner join places p ON f.id = p.feature_id
                  left join places pm ON f.parent_mountain_id = pm.feature_id
             where f.type='Mountain'"  
  end

  def down
    execute "delete from mountain_details;"
  end

end
