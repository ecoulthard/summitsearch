class AddLastRecommendationAtToPhoto < ActiveRecord::Migration
  def change
    add_column :photos, :last_liked_at, :datetime
    add_column :photos, :last_comment_at, :datetime
    add_column :photos, :total_comments, :integer
    add_column :photos, :total_likes, :integer
  end
end
