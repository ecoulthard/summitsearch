class CreateAreaFeatures < ActiveRecord::Migration
  def self.up
    create_table :area_features do |t|
      t.integer :area_id, :null => false
      t.integer :feature_id, :null => false
    end
    add_index :area_features, :area_id
    add_index :area_features, :feature_id
  end

  def self.down
    drop_table :area_features
  end
end
