class CreateVisits < ActiveRecord::Migration
  def up
    create_table :visits do |t|
      t.integer :ip_address_id, :null => false
      t.integer :visitable_id, :null => false
      t.string :visitable_type, :null => false
      t.datetime :current_visited_at, :datetime
      t.datetime :past_visited_at, :datetime
      t.integer :count, :default => 0
      t.boolean :facebook_like
      t.boolean :google_plus

      t.timestamps
    end
    add_index :visits, :ip_address_id
    add_index :visits, :visitable_id
    add_index :visits, :visitable_type

    #IpAddressAlbum.all.each do |visit|
    #  Visit.create(:ip_address_id => visit.ip_address_id, :visitable_id => visit.album_id, :visitable_type => "Album", :count => visit.visit_count, :current_visited_at => visit.updated_at, :past_visited_at => visit.updated_at, :facebook_like => visit.facebook_like, :google_plus => visit.google_plus)
    #end
    #IpAddressArea.all.each do |visit|
    #  Visit.create(:ip_address_id => visit.ip_address_id, :visitable_id => visit.area_id, :visitable_type => "Area", :count => visit.visit_count)
    #end
    #IpAddressFeature.all.each do |visit|
    #  Visit.create(:ip_address_id => visit.ip_address_id, :visitable_id => visit.feature_id, :visitable_type => "Feature", :count => visit.visit_count)
    #end
    #IpAddressPhoto.all.each do |visit|
    #  Visit.create(:ip_address_id => visit.ip_address_id, :visitable_id => visit.photo_id, :visitable_type => "Photo", :count => visit.visit_count, :facebook_like => visit.facebook_like, :google_plus => visit.google_plus)
    #end
    #IpAddressRoute.all.each do |visit|
    #  Visit.create(:ip_address_id => visit.ip_address_id, :visitable_id => visit.route_id, :visitable_type => "Route", :count => visit.visit_count)
    #end
    #IpAddressTripReport.all.each do |visit|
    #  Visit.create(:ip_address_id => visit.ip_address_id, :visitable_id => visit.trip_report_id, :visitable_type => "TripReport", :count => visit.visit_count, :facebook_like => visit.facebook_like, :google_plus => visit.google_plus)
    #end
  end

  def down
    drop_table :visits
  end
end
