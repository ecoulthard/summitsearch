class CopyFeaturesToPlaces < ActiveRecord::Migration
  def up
    execute "insert into places (type,name,name_status,name_reference,alternate_names,province,partial_name_match,match_names,reject_names,height,latitude,longitude,description,\"references\",importance,insert_id,update_id,created_at,updated_at,feature_id)
             select type,name,name_status,name_reference,alternate_names,province,partial_name_match,match_names,reject_names,height,latitude,longitude,description,\"references\",importance,insert_id,update_id,created_at,updated_at,id
	     from features where type != 'Mountain' order by type"  
  end

  def down
    execute "delete from places where type != 'Mountain'"
  end
end
