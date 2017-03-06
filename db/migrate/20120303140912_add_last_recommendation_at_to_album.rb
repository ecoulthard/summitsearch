class AddLastRecommendationAtToAlbum < ActiveRecord::Migration
  def change
    add_column :albums, :last_liked_at, :datetime
    add_column :albums, :last_comment_at, :datetime
    add_column :albums, :total_comments, :integer
    add_column :albums, :total_likes, :integer
  end
end
