class ChangeLengthOfRouteFields < ActiveRecord::Migration
  def change
    change_column :routes, :access, :text, :limit => 30720
    change_column :routes, :equipment, :text, :limit => 30720
    change_column :routes, :objective_hazard, :text, :limit => 30720
    change_column :routes, :name, :string, :limit => 128
    change_column :trip_reports, :title, :string, :limit => 128
    change_column :trip_reports, :abstract, :text, :limit => 30720
    change_column :trip_reports, :participants, :text, :limit => 30720
    change_column :trip_reports, :description, :text, :limit => 61440
    change_column :albums, :title, :string, :limit => 128
    change_column :photos, :title, :string, :limit => 128
    change_column :photos, :ref_title, :string, :limit => 128
    change_column :photos, :caption, :text, :limit => 30720
    change_column :photos, :description, :text, :limit => 30720
    change_column :photos, :vantage, :text, :limit => 30720
  end
end
