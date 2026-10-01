class UpdateArticleTotalCommentsJob < ApplicationJob
  queue_as :default

  def perform(article_class, article_id, timestamp)
    article = article_class.to_s.safe_constantize&.find_by(id: article_id)
    return unless article

    article.last_comment_at = timestamp
    article.total_comments = article.comments.count if article.respond_to?(:comments)
    article.save
  end
end
