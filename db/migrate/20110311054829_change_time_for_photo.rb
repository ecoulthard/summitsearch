class ChangeTimeForPhoto < ActiveRecord::Migration
  def self.up
    change_column :photos, :time, :datetime, :null => true
  end

  def self.down
    change_column :photos, :time, :datetime, :null => false
  end
end
