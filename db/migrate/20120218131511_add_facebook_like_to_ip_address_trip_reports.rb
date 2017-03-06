class AddFacebookLikeToIpAddressTripReports < ActiveRecord::Migration
  def change
    add_column :ip_address_trip_reports, :facebook_like, :boolean, :default => false
    add_column :ip_address_trip_reports, :google_plus, :boolean, :default => false
  end
end
