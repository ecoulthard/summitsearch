class CreateIpAddressTripReports < ActiveRecord::Migration
  def change
    create_table :ip_address_trip_reports do |t|
      t.integer :ip_address_id, :null => false
      t.integer :trip_report_id, :null => false
      t.integer :visit_count, :default => 0

      t.timestamps
    end
    add_index :ip_address_trip_reports, :ip_address_id
    add_index :ip_address_trip_reports, :trip_report_id
  end
end
