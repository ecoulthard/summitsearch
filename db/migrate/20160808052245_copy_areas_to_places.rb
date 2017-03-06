class CopyAreasToPlaces < ActiveRecord::Migration
  def up
    execute "insert into places (type,name,name_status,alternate_names,partial_name_match,match_names,reject_names,area,max_latitude,min_latitude,max_longitude,min_longitude,parent_area_id,forum_id,sub_region,description,\"references\",importance,insert_id,update_id,created_at,updated_at,area_id)
             select type,name,name_status,alternate_names,partial_name_match,match_names,reject_names,area,max_latitude,min_latitude,max_longitude,min_longitude,parent_area_id,forum_id,sub_region,description,\"references\",importance,insert_id,update_id,created_at,updated_at,id
	     from areas where type!='PeakGroup' order by area DESC"  
  end

  def down
    execute "delete from places where area_id IS NOT NULL and type!='PeakGroup'"
  end

end
