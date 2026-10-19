module ArticleDiscussion
  extend ActiveSupport::Concern

  included do
    has_one :topic, class_name: "Thredded::Topic"
    has_many :comments, through: :topic, source: :posts
  end

  # Area forum IDs retain their legacy values and resolve through the mapping.
  def forum
    geography = is_a?(TripReport) ? route : self
    legacy_id = geography&.areas&.where.not(forum_id: nil)&.order(:area)&.pick(:forum_id)
    if legacy_id
      Thredded::Messageboard.find_by(forem_forum_id: legacy_id)
    else
      Thredded::Messageboard.find_by(name: "Other Regions")
    end
  end

  # Public summaries and totals must never include pending or blocked content.
  def public_comments
    comments.joins(:postable).where(moderation_state: :approved,
      thredded_topics: { moderation_state: :approved })
  end
end
