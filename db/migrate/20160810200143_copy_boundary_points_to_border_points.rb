class CopyBoundaryPointsToBorderPoints < ActiveRecord::Migration
  def up
    execute "insert into border_points (latitude,longitude,place_id,local_index)
     select bp.latitude,bp.longitude,p.Id,local_index
     from boundary_points bp inner join places p ON bp.area_id = p.area_id;"
  end

  def down
    execute "DELETE FROM border_points"
  end
end
