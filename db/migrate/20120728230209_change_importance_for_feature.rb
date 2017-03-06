class ChangeImportanceForFeature < ActiveRecord::Migration
  def up
    change_column :features, :importance, :decimal, :precision => 19, :scale => 10
    change_column :areas, :importance, :decimal, :precision => 19, :scale => 10
    change_column :routes, :importance, :decimal, :precision => 19, :scale => 10
    change_column :photos, :importance, :decimal, :precision => 19, :scale => 10
    change_column :trip_reports, :importance, :decimal, :precision => 19, :scale => 10
  end

  def down
    change_column :features, :importance, :decimal, :precision => 6, :scale => 2
    change_column :areas, :importance, :decimal, :precision => 6, :scale => 2
    change_column :routes, :importance, :decimal, :precision => 6, :scale => 2
    change_column :photos, :importance, :decimal, :precision => 6, :scale => 2
    change_column :trip_reports, :importance, :decimal, :precision => 6, :scale => 2
  end
end
