class AddLastRecommendationAtToTripReport < ActiveRecord::Migration
  def change
    add_column :trip_reports, :last_liked_at, :datetime
    add_column :trip_reports, :last_comment_at, :datetime
    add_column :trip_reports, :total_comments, :integer
    add_column :trip_reports, :total_likes, :integer
  end
end
