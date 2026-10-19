module ForumTopicLinks
  extend ActiveSupport::Concern

  included do
    belongs_to :album, optional: true
    belongs_to :photo, optional: true
    belongs_to :trip_report, optional: true
    belongs_to :place, optional: true
    has_many :uploaded_photos, class_name: "Photo", foreign_key: :topic_id, dependent: :nullify
    after_save :refresh_linked_article_comments
    after_destroy :refresh_linked_article_comments
    after_commit :expire_linked_article_comment_summary
  end

  private

  def refresh_linked_article_comments
    ArticleCommentTotals.refresh_topic(self)
  end

  def expire_linked_article_comment_summary
    ArticleCommentTotals.expire_summary
  end
end
