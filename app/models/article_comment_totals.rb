class ArticleCommentTotals
  ARTICLES = { "album_id" => "Album", "photo_id" => "Photo", "trip_report_id" => "TripReport" }.freeze
  CACHE_KEY = "article_comments_version".freeze

  def self.refresh_topic(topic)
    return unless topic

    ARTICLES.each do |foreign_key, name|
      ids = [ topic[foreign_key], topic.saved_change_to_attribute(foreign_key)&.first ].compact.uniq.sort
      ids.each { |id| refresh(name.constantize.find_by(id: id)) }
    end
  end

  def self.refresh(article, touch: true)
    return unless article

    article.with_lock do
      comments = article.public_comments
      attributes = { total_comments: comments.count, last_comment_at: comments.maximum(:created_at) }
      attributes[:updated_at] = Time.current if touch
      article.update_columns(attributes)
    end
  end

  def self.expire_summary
    Rails.cache.write(CACHE_KEY, SecureRandom.hex(16))
  end

  def self.summary_cache_key
    { part: "comments", version: Rails.cache.fetch(CACHE_KEY) { "initial" } }
  end

  def self.refresh_all
    ARTICLES.values.each do |name|
      name.constantize.find_each { |article| refresh(article, touch: false) }
    end
    expire_summary
  end
end
