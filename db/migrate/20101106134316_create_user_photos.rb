class CreateUserPhotos < ActiveRecord::Migration
  def self.up
    create_table :user_photos do |t|
      t.integer :user_id, :null => false
      t.integer :photo_id, :null => false
      t.integer :visit_count, :default => 0
      t.integer :rating, :limit => 3

      t.timestamps
    end
    add_index :user_photos, :user_id
    add_index :user_photos, :photo_id
  end

  def self.down
    drop_table :user_photos
  end
end
