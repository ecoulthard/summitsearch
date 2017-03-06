#Updates the given article's total_likes and last_liked_at fields asyncronously.
class UpdateArticleTotalLikesWorker
  include Sidekiq::Worker

  def perform(article_class, article_id, timestamp, liked=true)
      article = article_class.constantize.find(article_id)

      article.last_liked_at = timestamp if liked
      article.total_likes = article.likes.count + article.user_likes.count
      article.save
  end
end
