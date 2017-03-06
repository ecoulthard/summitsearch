class CreateAreaPhotoInAreas < ActiveRecord::Migration
  def change
    create_table :area_photo_in_areas do |t|
      t.integer :area_id
      t.integer :photo_id
    end
    add_index :area_photo_in_areas, :area_id
    add_index :area_photo_in_areas, :photo_id
  end
end
