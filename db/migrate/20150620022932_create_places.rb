class CreatePlaces < ActiveRecord::Migration
  def change

    create_table :places do |t|
      t.string :type, :null => false, index: true
      t.string :name, :limit => 64, :null => false
      t.string :name_status, :default => 'Official', :limit => 32, :null => false
      t.integer :name_reference, :int, :limit => 1
      t.string :alternate_names, :limit => 128
      t.string :slug

      t.string :province, :limit => 64

      t.boolean :partial_name_match, :null => false
      t.text :match_names, :limit => 2048 #For definite matching of a photo or trip report
      t.text :reject_names, :limit => 2048 #For definite rejection of matches for photos and trip reports
      t.integer :nearby_namesake_id
      
      #Fields inherited from feature.
      t.integer :height, index: true
      t.integer :height_reference, :int, :limit => 1
      t.decimal :latitude, :precision => 8, :scale => 6
      t.decimal :longitude, :precision => 9, :scale => 6

      #Fields inherited from area.
      t.integer :area
      t.decimal :max_latitude, :precision => 8, :scale => 6
      t.decimal :min_latitude, :precision => 8, :scale => 6
      t.decimal :max_longitude, :precision => 9, :scale => 6
      t.decimal :min_longitude, :precision => 9, :scale => 6
      t.integer :parent_area_id
      t.integer :forum_id, index: true
      #Not sure about this field. We added it hoping to implement a feature using it but never did.
      t.boolean :sub_region, :default => false


      t.text :description
      t.text :references
      t.integer :ref_place_id
      t.decimal :importance, :precision => 28, :scale => 10

      t.integer :insert_id, :null => false, index: true
      t.integer :update_id

      t.timestamps

      #History is not used in any feature.
      #t.text :history

      #These area fields are not used ever so I am removing them.
      #t.integer :min_height
      #t.integer :max_height

      #These are mountain specific and should be moved to the mountains table once created.
      #t.integer :parent_mountain_id
      #t.integer :dist_to_parent

    end
    add_index :places, :slug, :unique => true
  end
end
