class CreatePlacePhotoInAreas < ActiveRecord::Migration
  def change
    create_table :place_photo_in_areas do |t|
      t.integer :place_id
      t.integer :photo_id
    end
    add_index :place_photo_in_areas, :place_id
    add_index :place_photo_in_areas, :photo_id
  end
end
