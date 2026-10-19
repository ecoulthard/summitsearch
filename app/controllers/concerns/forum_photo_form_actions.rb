module ForumPhotoFormActions
  extend ActiveSupport::Concern

  included do
    around_action :save_forum_photos_with_post, only: [ :create, :update ]
  end

  private

  def save_forum_photos_with_post
    return yield if params[:forum_photo_ids].blank?

    ActiveRecord::Base.transaction do
      yield
      next unless response.redirect?

      topic = if is_a?(Thredded::TopicsController)
        @new_topic&.topic
      else
        (@post_form&.post || @post)&.postable
      end
      next unless topic&.persisted?

      ForumPhotoAttachments.attach!(topic: topic, user: thredded_current_user, photo_ids: params[:forum_photo_ids])
    end
  rescue ForumPhotoAttachments::NotAllowed => error
    response.delete_header("Location")
    response.status = :unprocessable_entity
    response.content_type = "text/plain"
    self.response_body = error.message
  end
end
