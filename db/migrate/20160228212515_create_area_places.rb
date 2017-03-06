class CreateAreaPlaces < ActiveRecord::Migration
  def change
    create_table :area_places do |t|
      t.integer :area_id, :null => false
      t.integer :place_id, :null => false
    end
    add_index :area_places, :area_id
    add_index :area_places, :place_id
  end
end
