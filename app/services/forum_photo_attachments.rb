class ForumPhotoAttachments
  class NotAllowed < StandardError; end

  def self.authorize!(user, topic)
    candidate = Thredded::Post.new(postable: topic, messageboard: topic.messageboard)
    unless user && !user.thredded_anonymous? && Thredded::PostPolicy.new(user, candidate).create?
      raise NotAllowed, "Photos cannot be added to this discussion"
    end
  end

  def self.eligible(user, topic = nil)
    return Photo.none unless user && !user.thredded_anonymous?

    images = Photo.where.not(photo_file_name: [ nil, "" ]).or(
      Photo.where(id: ActiveStorage::Attachment.where(record_type: "Photo", name: "photo").select(:record_id)))
    images.where(user_id: user.id, topic_id: [ nil, topic&.id ].uniq)
  end

  def self.ids(value)
    unless value.nil? || value.is_a?(String) || (value.is_a?(Array) && value.all? { |id| id.is_a?(String) || id.is_a?(Integer) })
      raise NotAllowed, "Choose your available photos"
    end
    values = Array(value).flat_map { |item| item.to_s.split(",") }.reject(&:blank?)
    unless values.size <= 50 && values.all? { |id| /\A[1-9]\d*\z/.match?(id) }
      raise NotAllowed, "Choose up to 50 of your available photos"
    end
    values.map(&:to_i).uniq
  end

  def self.attach!(topic:, user:, photo_ids:)
    selected = ids(photo_ids)
    return if selected.empty?

    Thredded::Topic.transaction do
      # Recheck policies and eligibility under locks, including concurrent claims.
      topic = Thredded::Topic.lock.find(topic.id)
      authorize!(user, topic)
      photos = Photo.where(id: selected).order(:id).lock.to_a
      available = eligible(user, topic).where(id: selected).pluck(:id)
      unless photos.size == selected.size && available.sort == selected.sort
        raise NotAllowed, "Choose only your available photos; photos attached to another discussion cannot be moved"
      end
      Photo.where(id: selected).update_all(topic_id: topic.id)
    end
  end
end
