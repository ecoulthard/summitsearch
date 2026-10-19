ENV["RAILS_ENV"] = "test"
require_relative "../../config/environment"
require "minitest/autorun"
require "action_controller/test_case"
require_relative "../support/forum_database"

# Real Thredded models and callbacks, without legacy fixtures or shared data.
class ArticleCommentTest < Minitest::Test
  include ForumDatabase

  def comment(content = "A comment", user: @user, article: @article)
    ArticleComment.create!(article: article, user: user, content: content)
  end

  def test_first_comment_is_atomic_and_belongs_to_the_commenter
    assert_raises(ActiveRecord::RecordInvalid) { comment(" ") }
    assert_equal 0, Thredded::Topic.count
    assert_equal 0, Thredded::Post.count
    assert_empty ActiveJob::Base.queue_adapter.enqueued_jobs

    post = comment
    assert_equal 1, ActiveJob::Base.queue_adapter.enqueued_jobs.count { |job| job[:job] == Thredded::AutoFollowAndNotifyJob }
    assert_equal @user, post.user
    assert_equal @user, post.postable.user
    assert_equal @article, post.postable.album
    assert_equal 1, @article.reload.total_comments
    assert_equal post.created_at, @article.last_comment_at
    assert Thredded::UserTopicFollow.exists?(user_id: 10, topic_id: post.postable_id)
    comment("Another comment", article: Album.find(20))
    assert_equal 1, Thredded::Topic.count
    assert_equal 2, @article.reload.total_comments
  end

  def test_guests_and_denied_boards_cannot_create_comments
    [ nil, Thredded::NullUser.new ].each do |user|
      assert_raises(ArticleComment::NotAllowed) { comment(user: user) }
    end
    @user.define_singleton_method(:thredded_can_write_messageboards) { Thredded::Messageboard.none }
    assert_raises(ArticleComment::NotAllowed) { comment }
    assert_equal 0, Thredded::Topic.count
    @board.update!(locked: true)
    assert_raises(ArticleComment::NotAllowed) { comment(user: User.find(10)) }
  end

  def test_replies_use_the_same_locked_blocked_and_read_policies_as_the_forum
    post = comment
    topic = post.postable
    topic.update!(locked: true)
    [ @user, User.find(12) ].each do |user|
      refute Thredded::PostPolicy.new(user, Thredded::Post.new(postable_id: topic.id, messageboard: @board)).create?
      assert_raises(ArticleComment::NotAllowed) { comment(user: user) }
    end
    topic.update!(locked: false, moderation_state: :blocked)
    assert_raises(ArticleComment::NotAllowed) { comment }
    topic.update!(moderation_state: :approved)
    @user.define_singleton_method(:thredded_can_read_messageboard?) { |_board| false }
    assert_raises(ArticleComment::NotAllowed) { comment }
    assert_equal 1, Thredded::Post.count
  end

  def test_forum_post_edits_moderation_deletions_and_topic_deletion_refresh_totals
    first = comment
    topic = first.postable
    later = topic.posts.create!(content: "Forum reply", user: @user, messageboard: @board,
      created_at: first.created_at + 1.minute)
    assert_equal 2, @article.reload.total_comments
    assert_equal later.created_at, @article.last_comment_at
    old_version = Rails.cache.read(ArticleCommentTotals::CACHE_KEY)
    later.update!(content: "Edited from forum")
    refute_equal old_version, Rails.cache.read(ArticleCommentTotals::CACHE_KEY)
    later.update!(moderation_state: :pending_moderation)
    assert_equal 1, @article.reload.total_comments
    assert_equal first.created_at, @article.last_comment_at
    later.update!(moderation_state: :approved)
    assert_equal 2, @article.reload.total_comments
    topic.update!(moderation_state: :blocked)
    assert_equal 0, @article.reload.total_comments
    assert_nil @article.last_comment_at
    assert_empty @article.public_comments
    topic.update!(moderation_state: :approved)
    later.destroy!
    assert_equal 1, @article.reload.total_comments
    topic.destroy!
    assert_equal 0, @article.reload.total_comments
    assert_nil @article.last_comment_at
  end

  def test_pending_posts_stay_private_and_do_not_increase_public_totals
    comment
    @user.thredded_user_detail.update!(moderation_state: :pending_moderation)
    post = comment("Needs review")
    assert post.pending_moderation?
    assert_equal 1, @article.reload.total_comments
    guest = Thredded::NullUser.new
    refute Thredded::PostPolicy.new(guest, post).read?
    refute_includes Thredded::PostPolicy::Scope.new(guest, post.postable.posts).resolve, post
    assert Thredded::PostPolicy.new(@user, post).read?
  end

  def test_stale_comment_jobs_recompute_instead_of_overwriting_activity_time
    post = comment
    UpdateArticleTotalCommentsJob.perform_now("Album", @article.id, 20.years.ago)
    assert_equal 1, @article.reload.total_comments
    assert_equal post.created_at, @article.last_comment_at
  end

  def test_cutover_recount_rebuilds_totals_without_touching_article_timestamps
    post = comment
    timestamp = @article.reload.updated_at
    @article.update_columns(total_comments: 999, last_comment_at: nil)
    old_key = ArticleCommentTotals.summary_cache_key
    ArticleCommentTotals.refresh_all
    assert_equal 1, @article.reload.total_comments
    assert_equal post.created_at, @article.last_comment_at
    assert_equal timestamp, @article.updated_at
    refute_equal old_key, ArticleCommentTotals.summary_cache_key
  end

  def test_photo_and_trip_report_comments_and_explicit_area_mapping
    Photo.insert_all!([ { id: 42, title: "Mountain", ref_latitude: 0, ref_longitude: 0,
      ref_title: "", ref_content: "", user_id: 10 } ])
    Route.insert_all!([ { id: 50, type: "Route", name: "Trail", travel_time: "", insert_id: 10 } ])
    TripReport.insert_all!([ { id: 60, title: "Trip", participants: "", route_id: 50, user_id: 10 } ])
    Place.insert_all!([ { id: 70, type: "Place", name: "Area", partial_name_match: false,
      insert_id: 10, forum_id: 999, area: 1 } ])
    PlaceAlbumInArea.insert_all!([ { place_id: 70, album_id: 20 } ])
    PlacePhotoInArea.insert_all!([ { place_id: 70, photo_id: 42 } ])
    PlaceRouteInArea.insert_all!([ { place_id: 70, route_id: 50 } ])
    # An area mapping must resolve through forem_forum_id, not the board PK.
    mapped = Thredded::Messageboard.create!(name: "Mapped", description: "Area", forem_forum_id: 999)
    [ @article, Photo.find(42), TripReport.find(60) ].each do |article|
      assert_equal mapped, article.forum
      post = comment(article: article)
      assert_equal mapped, post.messageboard
      assert_equal post.postable, article.reload_topic
      assert_equal 1, article.reload.total_comments
      post.destroy!
      assert_equal 0, article.reload.total_comments
    end
  end

  def test_simultaneous_first_comments_create_one_topic
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          old_path = connection.schema_search_path
          connection.schema_search_path = "#{@schema}, public"
          ready << true
          start.pop
          ArticleComment.create!(article: Album.find(20), user: User.find(10 + index), content: "Concurrent #{index}")
        ensure
          connection.schema_search_path = old_path
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.each(&:value)
    assert_equal 1, Thredded::Topic.count
    assert_equal 2, Thredded::Post.count
    assert_equal 2, @article.reload.total_comments
  end

  def test_thredded_moderation_command_refreshes_article_totals
    first = comment
    moderator = User.find(12)
    Thredded::ModeratePost.run!(post: first, moderation_state: :blocked, moderator: moderator)
    assert_equal 0, @article.reload.total_comments
    assert_nil @article.last_comment_at
    Thredded::ModeratePost.run!(post: first, moderation_state: :approved, moderator: moderator)
    assert_equal 1, @article.reload.total_comments
  end

  def test_article_controller_handles_success_and_validation_failure
    controller = article_controller(@user)
    controller.request.set_header("REQUEST_METHOD", "POST")
    controller.request.set_header("action_dispatch.request.request_parameters", { "text" => "From the article" })
    controller.dispatch(:create_comment, controller.request, controller.response)
    assert_equal 302, controller.response.status
    assert_equal 1, @article.reload.total_comments
    assert_equal "From the article", @article.comments.first.content

    controller = article_controller(@user)
    controller.request.set_header("REQUEST_METHOD", "POST")
    controller.request.set_header("action_dispatch.request.request_parameters", { "text" => " " })
    controller.dispatch(:create_comment, controller.request, controller.response)
    assert_equal 302, controller.response.status
    assert_equal 1, @article.reload.total_comments
    assert_match(/blank/, controller.flash[:alert])
  end

  def test_article_display_filters_moderation_and_renders_markdown_and_deleted_users
    visible = comment("**Visible**")
    visible.update_columns(user_id: nil)
    private_post = comment("Secret pending text")
    private_post.update!(moderation_state: :pending_moderation)
    controller = article_controller(nil)
    controller.send(:loadComments)
    html = controller.render_to_string(partial: "articles/comments")
    assert_includes html, "<strong>Visible</strong>"
    assert_includes html, "Deleted user"
    refute_includes html, "Secret pending text"
    refute_includes html, "Post Comment"

    controller = article_controller(@user)
    controller.send(:loadComments)
    html = controller.render_to_string(partial: "articles/comments")
    assert_includes html, "Post Comment"
    assert_includes html, "Secret pending text"
    assert_includes html, "/albums/#{@article.to_param}/create_comment"
  end

  def test_legacy_html_and_photo_tokens_use_safe_rendering_in_both_interfaces
    Photo.insert_all!([ { id: 42, title: "Embedded mountain", photo_file_name: "mountain.jpg",
      ref_latitude: 0, ref_longitude: 0, ref_title: "", ref_content: "", photo_width: 800, photo_height: 600 } ])
    post = comment
    post.update!(source: "forem", content: "<p>Original <strong>HTML</strong></p><script>alert(1)</script>[[photo=42]][[photo=999999]]After")
    controller = article_controller(nil)
    html = post.filtered_content(controller.view_context)
    assert_includes html, "<strong>HTML</strong>"
    assert_includes html, "Embedded mountain"
    assert_includes html, "After"
    refute_includes html, "<script>"
    refute_includes html, "[[photo="
    view = Thredded::PostView.new(post, Thredded::PostPolicy.new(Thredded::NullUser.new, post))
    assert_equal html, view.filtered_content(controller.view_context)
  end

  def test_forum_topic_title_hook_links_back_to_its_article
    post = comment
    html = Thredded.view_hooks.topic_page.title.render(article_controller(@user).view_context, topic: post.postable) { "Title" }
    assert_includes html, "Discussion of"
    assert_includes html, @article.title
    assert_includes html, Rails.application.routes.url_helpers.album_path(@article)
  end

  private

  def article_controller(user)
    controller = AlbumsController.new
    request = ActionController::TestRequest.create(AlbumsController)
    request.path_parameters = { controller: "albums", action: "show", id: @article.id.to_s }
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["warden"] = Warden::Proxy.new(request.env, Warden::Manager.new(nil))
    request.env["warden"].set_user(user, scope: :user, store: false) if user
    controller.set_request!(request)
    controller.set_response!(ActionDispatch::TestResponse.new)
    controller.define_singleton_method(:current_user) { user }
    controller.instance_variable_set(:@album, @article)
    controller
  end
end
