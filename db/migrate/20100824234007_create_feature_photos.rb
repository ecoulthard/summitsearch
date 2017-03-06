class CreateFeaturePhotos < ActiveRecord::Migration
  def self.up
    create_table :feature_photos do |t|
      t.integer :feature_id, :null => false
      t.integer :photo_id, :null => false
      t.boolean :in_title, :default => false
    end
    add_index :feature_photos, :feature_id
    add_index :feature_photos, :photo_id
  end

  def self.down
    drop_table :feature_photos
  end
end
