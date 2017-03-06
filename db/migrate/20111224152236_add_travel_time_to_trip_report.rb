class AddTravelTimeToTripReport < ActiveRecord::Migration
  def change
    add_column :trip_reports, :travel_time, :string
  end
end
