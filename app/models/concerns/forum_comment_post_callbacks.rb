module ForumCommentPostCallbacks
  extend ActiveSupport::Concern

  included do
    after_save :refresh_article_comment_totals
    after_destroy :refresh_article_comment_totals
    after_commit :expire_article_comment_summary
  end

  private

  def refresh_article_comment_totals
    ArticleCommentTotals.refresh_topic(postable)
    if saved_change_to_postable_id? && postable_id_before_last_save != postable_id
      ArticleCommentTotals.refresh_topic(Thredded::Topic.find_by(id: postable_id_before_last_save))
    end
  end

  def expire_article_comment_summary
    ArticleCommentTotals.expire_summary
  end
end
