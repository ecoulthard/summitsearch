class RefreshSlugs < ActiveRecord::Migration
  def change
    remove_index :places, column: :slug 
    execute "DELETE FROM friendly_id_slugs WHERE sluggable_type IN ('Feature','Area','Place')"
    
    #execute "UPDATE places SET slug=regexp_replace(Name, '(^Mount\s+)|(\s+Peak$)|(\s+Mountain$)','')"
    
    execute "UPDATE places set slug=lower(regexp_replace(ltrim(rtrim(name)), '[^A-Za-z0-9]+', '-', 'g'))"
    execute "UPDATE places set slug=regexp_replace(slug, '\-+', '-', 'g')"
    execute "UPDATE places set slug=regexp_replace(slug, '(^\-+)|(\-+$)', '', 'g')"
    
    execute "UPDATE places p SET slug=slug || '-' || rank FROM (SELECT m.Id, RANK() OVER(PARTITION BY slug ORDER BY area DESC NULLS LAST, dist_to_parent DESC NULLS LAST, height DESC NULLS LAST, Latitude DESC NULLS LAST) AS rank FROM places m left join mountain_details d ON m.id = d.mountain_id) r WHERE p.Id = r.Id AND rank > 1"
    execute "UPDATE places p SET slug=slug || '-' || rank FROM (SELECT m.Id, RANK() OVER(PARTITION BY slug ORDER BY area DESC NULLS LAST, dist_to_parent DESC NULLS LAST, height DESC NULLS LAST, Latitude DESC NULLS LAST) AS rank FROM places m left join mountain_details d ON m.id = d.mountain_id) r WHERE p.Id = r.Id AND rank > 1"

    add_index :places, :slug, :unique => true

    execute "insert into friendly_id_slugs (slug, sluggable_id, sluggable_type) SELECT slug, id, 'Place' FROM places"
  end
end
