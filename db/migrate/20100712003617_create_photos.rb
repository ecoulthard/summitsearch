class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|
      t.string :title, :limit => 64, :null => false
      t.datetime :time, :null => false
      t.integer :feature_id
      t.integer :trip_report_id
      t.integer :area_id
      t.decimal :latitude, :null => false, :precision => 8, :scale => 6
      t.decimal :longitude, :null => false, :precision => 9, :scale => 6
      t.string :vantage
      t.text :caption, :limit => 1024, :null => false
      t.text :description, :limit => 4096
      t.integer :user_id
      t.integer :height
      t.decimal :ref_latitude, :null => false, :precision => 8, :scale => 6
      t.decimal :ref_longitude, :null => false, :precision => 9, :scale => 6
      t.string :ref_title, :null => false, :limit => 30
      t.text :ref_content, :null => false, :limit => 1024
      t.integer :update_id
      t.decimal :importance, :precision => 6, :scale => 2

      t.timestamps
    end
    add_index :photos, :user_id
    add_index :photos, :feature_id
    add_index :photos, :trip_report_id
  end

  def self.down
    drop_table :photos
  end
end
