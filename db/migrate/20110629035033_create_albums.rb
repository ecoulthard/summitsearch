class CreateAlbums < ActiveRecord::Migration
  def self.up
    create_table :albums do |t|
      t.string :title, :limit => 64
      t.text :description, :limit => 30720
      t.datetime :time
      t.integer :user_id
      t.integer :feature_id
      t.integer :route_id
      t.integer :area_id
      t.decimal :ref_latitude, :null => false, :precision => 8, :scale => 6
      t.decimal :ref_longitude, :null => false, :precision => 9, :scale => 6
      t.string :ref_title, :null => false, :limit => 30
      t.text :ref_content, :null => false, :limit => 1024
      t.integer :photo_id
      t.integer :update_id
      t.decimal :importance, :precision => 6, :scale => 2
      t.boolean :deleted

      t.timestamps
    end
    add_index :albums, :user_id
  end

  def self.down
    drop_table :albums
  end
end
