class CreatePlacePhotos < ActiveRecord::Migration
  def change
    create_table :place_photos do |t|
      t.integer :place_id
      t.integer :photo_id
      t.boolean :in_title, :default => false

    end
    add_index :place_photos, :place_id
    add_index :place_photos, :photo_id
  end
end
