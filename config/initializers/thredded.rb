Thredded.user_class = "User"
Thredded.current_user_method = :current_user
Thredded.user_name_column = :username
Thredded.user_display_name_method = :display_name
Thredded.user_path = ->(user) { main_app.user_path(user) }
Thredded.email_from = Rails.application.config.notifier_email.presence || "notifier@summitsearch.org"

# Keep existing forum administration separate from the site's editor/admin roles.
Thredded.admin_column = :forem_admin
Thredded.moderator_column = :forem_admin
Thredded.content_visible_while_pending_moderation = false

Rails.application.config.to_prepare do
  Thredded::Topic.include ForumTopicLinks
  Thredded::Post.include ForumCommentPostCallbacks
  Thredded::Post.prepend ForumPostContent
  Thredded::Post.prepend ForumPostPagination
  Thredded::PrivatePost.prepend ForumPostPagination
  [ Thredded::Topic, Thredded::PrivateTopic ].each do |model|
    model.scope :on_page, ->(page_num) { forum_page(page_num) }
  end
  Thredded::PostPolicy.prepend ForumPostPermissions
  Thredded::TopicsController.include ForumPhotoFormActions
  Thredded::PostsController.include ForumPhotoFormActions
  Thredded.view_hooks.post_form.content_text_area.config.after do |form:, **|
    topic = form.object.topic
    if topic.is_a?(Thredded::Topic)
      render "forum_photos/picker", topic: topic, textarea_id: form.field_id(:content)
    end
  end
  Thredded.view_hooks.topic_page.title.config.after do |topic:, **|
    render "articles/forum_article_links", topic: topic.to_model
  end
  # Thredded supplies its own login requirements and Pundit policies. The host
  # application's editor/admin gates would otherwise prevent member posting.
  Thredded::ApplicationController.skip_before_action :authenticate_user!, :editor_required, :admin_required, raise: false
end
