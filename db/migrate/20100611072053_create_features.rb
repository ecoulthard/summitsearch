class CreateFeatures < ActiveRecord::Migration
  def self.up
    create_table :features do |t|
      t.string :type, :null => false
      t.string :name, :limit => 32, :null => false
      t.string :name_status, :default => 'Official', :limit => 32, :null => false
      t.string :alternate_names, :limit => 128
      t.string :province, :limit => 64
      t.text :match_names, :limit => 2048 #For definite matching of a photo or trip report
      t.text :reject_names, :limit => 2048 #For definite rejection of matches for photos and trip reports
      t.integer :height, :null => false
      t.decimal :latitude, :null => false, :precision => 8, :scale => 6
      t.decimal :longitude, :null => false, :precision => 9, :scale => 6
      t.text :description
      t.text :history
      t.text :referrences
      t.integer :parent_mountain_id
      t.integer :dist_to_parent
      t.boolean :partial_name_match, :null => false
      t.integer :insert_id, :null => false
      t.integer :update_id
      t.decimal :importance, :precision => 6, :scale => 2

      t.timestamps
    end
    add_index :features, :insert_id
    add_index :features, :type
    add_index :features, :height
    add_index :features, :dist_to_parent
  end

  def self.down
    drop_table :features
  end
end
