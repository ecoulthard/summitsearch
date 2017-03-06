class CreateAreas < ActiveRecord::Migration
  def self.up
    create_table :areas do |t|
      t.string :type, :null => false
      t.string :name, :null => false, :limit => 64
      t.string :alternate_names, :limit => 128
      t.string :name_status, :null => false, :default => 'Official', :limit => 32
      t.text :match_names, :limit => 2048 #For definite matching of a photo or trip report
      t.text :reject_names, :limit => 2048 #For definite rejection of matches for photos and trip reports
      t.text :description
      t.text :referrences
      t.integer :area
      t.integer :min_height
      t.integer :max_height
      t.decimal :max_latitude, :null => false, :precision => 8, :scale => 6
      t.decimal :min_latitude, :null => false, :precision => 8, :scale => 6
      t.decimal :max_longitude, :null => false, :precision => 9, :scale => 6
      t.decimal :min_longitude, :null => false, :precision => 9, :scale => 6
      t.integer :parent_area_id
      t.boolean :partial_name_match, :null => false
      t.integer :insert_id, :null => false
      t.integer :update_id
      t.decimal :importance, :precision => 6, :scale => 2

      t.timestamps
    end
    add_index :areas, :insert_id
    add_index :areas, :type
  end

  def self.down
    drop_table :areas
  end
end



