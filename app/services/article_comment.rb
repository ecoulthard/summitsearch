class ArticleComment
  class NotAllowed < StandardError; end

  def self.create!(article:, user:, content:, reply_to_id: nil, photo_ids: nil)
    raise NotAllowed, "Sign in to comment" unless user && !user.thredded_anonymous?

    article.with_lock do
      # Serialize first comments on the article, and ignore a cached nil topic.
      topic = article.reload_topic
      if topic
        topic.lock!
      else
        board = article.forum
        raise NotAllowed, "Comments are not available for this article yet" unless board

        title = "#{article.model_name.human}: #{article.title.presence || article.id}"
        topic = board.topics.build(title: title.truncate(Thredded.topic_title_length_range.max), user: user)
        topic[article.model_name.singular.foreign_key] = article.id
        raise NotAllowed, "You do not have permission to comment" unless Thredded::TopicPolicy.new(user, topic).create?
      end

      post = topic.posts.build(content: content, user: user, messageboard: topic.messageboard)
      raise NotAllowed, "Commenting is locked or unavailable" unless Thredded::PostPolicy.new(user, post).create?

      if reply_to_id.present?
        reply = topic.persisted? && topic.posts.find_by(id: reply_to_id)
        raise NotAllowed, "That comment is unavailable" unless reply && Thredded::PostPolicy.new(user, reply).read?
      end

      new_topic = topic.new_record?
      topic.save! if new_topic
      post.save!
      ForumPhotoAttachments.attach!(topic: topic, user: user, photo_ids: photo_ids)
      Thredded::UserTopicReadState.touch!(user.id, post)
      if new_topic && article.user && Thredded::TopicPolicy.new(article.user, topic).read?
        Thredded::UserTopicFollow.create_unless_exists(article.user.id, topic.id, :manual)
      end
      post
    end
  end
end
