class AddMatchNamesAndRejectNamesToRoute < ActiveRecord::Migration
  def self.up
    add_column :routes, :match_names, :text, :limit => 2048 #For definite matching of a photo or trip report
    add_column :routes, :reject_names, :text, :limit => 2048 #For definite rejection of matches for photos and trip reports
  end

  def self.down
    remove_column :routes, :reject_names
    remove_column :routes, :match_names
  end
end
