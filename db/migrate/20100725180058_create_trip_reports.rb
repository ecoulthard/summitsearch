class CreateTripReports < ActiveRecord::Migration
  def self.up
    create_table :trip_reports do |t|
      t.string :title, :null => false, :limit => 64
      t.datetime :start_time, :null => false
      t.datetime :end_time, :null => false
      t.text :abstract, :limit => 512
      t.text :participants, :null => false, :limit => 512
      t.text :description, :null => false, :limit => 30720
      t.integer :route_id, :null => false
      t.integer :user_id, :null => false
      t.integer :update_id
      t.decimal :importance, :precision => 6, :scale => 2

      t.timestamps
    end
    add_index :trip_reports, :user_id
    add_index :trip_reports, :route_id
  end

  def self.down
    drop_table :trip_reports
  end
end
