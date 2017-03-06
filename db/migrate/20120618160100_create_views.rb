class CreateViews < ActiveRecord::Migration
  def up
    #drop_table :views
    create_table :views do |t|
      t.integer :user_id
      t.integer :viewable_id
      t.string :viewable_type
      t.integer :count
      t.integer :rating
      t.datetime :current_viewed_at
      t.datetime :past_viewed_at

      t.timestamps
    end
    add_index :views, :user_id
    add_index :views, :viewable_id
    add_index :views, :viewable_type

    #UserAlbum.all.each do |view|
    #  View.create(:user_id => view.user_id, :viewable_id => view.album_id, :viewable_type => "Album", :count => view.visit_count, :rating => view.rating, :current_viewed_at => view.updated_at, :past_viewed_at => view.updated_at)
    #end
    #UserPhoto.all.each do |view|
    #  View.create(:user_id => view.user_id, :viewable_id => view.photo_id, :viewable_type => "Photo", :count => view.visit_count, :rating => view.rating, :current_viewed_at => view.updated_at, :past_viewed_at => view.updated_at)
    #end
    #UserTripReport.all.each do |view|
    #  View.create(:user_id => view.user_id, :viewable_id => view.trip_report_id, :viewable_type => "TripReport", :count => view.visit_count, :rating => view.rating, :current_viewed_at => view.updated_at, :past_viewed_at => view.updated_at)
    #end
  end

  def down
    drop_table :views
  end
end
