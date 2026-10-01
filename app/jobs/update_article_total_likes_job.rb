class UpdateArticleTotalLikesJob < ApplicationJob
  queue_as :default

  def perform(article_class, article_id, timestamp, liked = true)
    article = article_class.to_s.safe_constantize&.find_by(id: article_id)
    return unless article

    article.last_liked_at = timestamp if liked
    likes_count = (article.respond_to?(:likes) ? article.likes.count : 0) +
                  (article.respond_to?(:user_likes) ? article.user_likes.count : 0)
    article.total_likes = likes_count
    article.save
  end
end
