class DropConstraintsForPhoto < ActiveRecord::Migration
  def self.up
    change_column :photos, :title, :string, :limit => 64, :null => true
    change_column :photos, :latitude, :decimal, :precision => 8, :scale => 6, :null => true
    change_column :photos, :longitude, :decimal, :precision => 9, :scale => 6, :null => true
    change_column :photos, :caption, :text, :limit => 2048, :null => true, :default => nil
  end

  def self.down
    change_column :photos, :title, :string, :limit => 64, :null => false
    change_column :photos, :latitude, :decimal, :precision => 8, :scale => 6, :null => false
    change_column :photos, :longitude, :decimal, :precision => 9, :scale => 6, :null => false 
    change_column :photos, :caption, :text, :limit => 2048, :null => false 
  end
end
