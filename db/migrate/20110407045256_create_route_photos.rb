class CreateRoutePhotos < ActiveRecord::Migration
  def self.up
    create_table :route_photos do |t|
      t.integer :route_id, :null => false
      t.integer :photo_id, :null => false
      t.boolean :in_title, :default => false
    end
    add_index :route_photos, :route_id
    add_index :route_photos, :photo_id
  end

  def self.down
    drop_table :route_photos
  end
end
