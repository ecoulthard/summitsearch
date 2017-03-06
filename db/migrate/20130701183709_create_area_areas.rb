class CreateAreaAreas < ActiveRecord::Migration
  def change
    create_table :area_areas do |t|
      t.integer :parent_area_id, :null => false
      t.integer :child_area_id, :null => false
    end
    add_index :area_areas, :parent_area_id
    add_index :area_areas, :child_area_id
  end
end
