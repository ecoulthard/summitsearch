class AddFieldsToTripReport < ActiveRecord::Migration
  def change
    add_column :trip_reports, :type, :string
    add_column :trip_reports, :snowshoeing, :boolean
    add_column :trip_reports, :skiing, :boolean
  end
end
