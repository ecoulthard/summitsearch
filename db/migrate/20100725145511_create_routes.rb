class CreateRoutes < ActiveRecord::Migration
  def self.up
    create_table :routes do |t|
      t.string :type, :null => false
      t.string :name, :null => false, :limit => 64
      t.string :alternate_names, :limit => 128
      t.string :name_status, :null => false, :default => 'Official', :limit => 32
      t.text :equipment, :limit => 512
      t.text :description, :limit => 30720
      t.text :referrences
      t.string :travel_time, :null => false
      t.integer :difficulty
      t.decimal :distance, :precision => 5, :scale => 2
      t.integer :height_gain
      t.integer :height_loss
      t.integer :feature_id
      t.boolean :partial_name_match
      t.integer :insert_id, :null => false
      t.integer :update_id
      t.decimal :importance, :precision => 6, :scale => 2

      t.timestamps
    end
    add_index :routes, :insert_id
    add_index :routes, [:type, :feature_id]
  end

  def self.down
    drop_table :routes
  end
end
