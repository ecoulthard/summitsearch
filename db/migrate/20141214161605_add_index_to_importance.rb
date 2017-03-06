class AddIndexToImportance < ActiveRecord::Migration
  def change
    add_index :albums, :importance
    add_index :areas, :importance
    add_index :features, :importance
    add_index :people, :importance
    add_index :photos, :importance
    add_index :routes, :importance
    add_index :trip_reports, :importance
  end
end
