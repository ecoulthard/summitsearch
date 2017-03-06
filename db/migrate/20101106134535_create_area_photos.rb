class CreateAreaPhotos < ActiveRecord::Migration
  def self.up
    create_table :area_photos do |t|
      t.integer :area_id, :null => false
      t.integer :photo_id, :null => false
      t.boolean :in_title, :default => false
    end
    add_index :area_photos, :area_id
    add_index :area_photos, :photo_id
  end

  def self.down
    drop_table :area_photos
  end
end
