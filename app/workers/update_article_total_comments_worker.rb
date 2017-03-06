#Updates the given article's total_likes and last_liked_at fields asyncronously.
class UpdateArticleTotalCommentsWorker
  include Sidekiq::Worker

  def perform(article_class, article_id, timestamp)
      article = article_class.constantize.find(article_id)

      article.last_comment_at = timestamp
      article.total_comments = article.comments.count
      article.save
  end
end
