class UpdateArticleTotalCommentsJob < ApplicationJob
  queue_as :default

  def perform(article_class, article_id, timestamp)
    article = article_class.to_s.safe_constantize&.find_by(id: article_id)
    return unless article

    ArticleCommentTotals.refresh(article)
    ArticleCommentTotals.expire_summary
  end
end
