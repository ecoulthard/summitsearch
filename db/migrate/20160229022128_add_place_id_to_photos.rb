class AddPlaceIdToPhotos < ActiveRecord::Migration
  def change
    add_column :photos, :place_id, :int
    add_index :photos, :place_id
  end
end
