class DropConstraintsForTripReports < ActiveRecord::Migration
  def up
    change_column :trip_reports, :title, :string, :limit => 64, :null => true
    change_column :trip_reports, :description, :text, :limit => 30720, :null => true, :default => nil
    change_column :trip_reports, :start_time, :datetime, :null => true
    change_column :trip_reports, :end_time, :datetime, :null => true
  end

  def down
    change_column :trip_reports, :title, :string, :limit => 64, :null => false
    change_column :trip_reports, :description, :text, :limit => 30720, :null => false
    change_column :trip_reports, :start_time, :datetime, :null => false
    change_column :trip_reports, :end_time, :datetime, :null => false
  end
end
