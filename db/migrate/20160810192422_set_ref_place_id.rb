class SetRefPlaceId < ActiveRecord::Migration
  def up
     execute "update places set ref_place_id=ref_p.id
     from features f inner join places ref_p on f.ref_feature_id = ref_p.feature_id
     where places.feature_id = f.id;
     update places set ref_place_id=ref_p.id
     from areas a inner join places ref_p on a.ref_area_id = ref_p.area_id
     where places.area_id = a.id"
  end

  def down
    execute "update places set ref_place_id=NULL"
  end



end
