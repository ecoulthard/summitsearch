class CreateUserTripReports < ActiveRecord::Migration
  def self.up
    create_table :user_trip_reports do |t|
      t.integer :user_id, :null => false
      t.integer :trip_report_id, :null => false
      t.integer :visit_count, :default => 0
      t.integer :rating, :limit => 3

      t.timestamps
    end
    add_index :user_trip_reports, :user_id
    add_index :user_trip_reports, :trip_report_id
  end

  def self.down
    drop_table :user_trip_reports
  end
end
