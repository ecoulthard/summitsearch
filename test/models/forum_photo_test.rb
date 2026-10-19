ENV["RAILS_ENV"] = "test"
require_relative "../../config/environment"
require "minitest/autorun"
require "action_controller/test_case"
require "base64"
require_relative "../support/forum_database"

class ForumPhotoTest < Minitest::Test
  include ForumDatabase

  def setup
    super
    Photo.insert_all!([ 100, 101, 102, 103, 104 ].map do |id|
      { id: id, title: "Photo #{id}", user_id: id == 101 ? 10 : 11,
        photo_file_name: [ 102, 104 ].include?(id) ? nil : "photo.jpg", ref_latitude: 0, ref_longitude: 0,
        ref_title: "", ref_content: "" }
    end)
    @topic = Thredded::Topic.create!(title: "Photo discussion", user: @user, messageboard: @board)
    @other_topic = Thredded::Topic.create!(title: "Other discussion", user: @user, messageboard: @board)
    Photo.where(id: 103).update_all(topic_id: @other_topic.id)
    Place.insert_all!([ { id: 70, type: "Place", name: "Mountain", partial_name_match: false,
      insert_id: 10, latitude: 51, longitude: -115 } ])
  end

  def teardown
    ActiveStorage::Blob.find_each { |blob| blob.service.delete(blob.key) }
    super
  end

  def attach(ids, user: @user, topic: @topic)
    ForumPhotoAttachments.attach!(topic: topic, user: user, photo_ids: ids)
  end

  def test_only_owned_available_photos_can_be_attached_and_not_reparented
    assert_equal [ 100 ], ForumPhotoAttachments.eligible(@user, @topic).pluck(:id)
    attach([ "100", "100" ])
    assert_equal @topic, Photo.find(100).parent_topic
    assert_equal [ 100 ], @topic.uploaded_photos.pluck(:id)
    attach([ "100" ])
    [ 101, 102, 103, 104, 999 ].each do |id|
      assert_raises(ForumPhotoAttachments::NotAllowed) { attach([ "100", id.to_s ]) }
    end
    assert_nil Photo.find(101).topic_id
    assert_equal @other_topic.id, Photo.find(103).topic_id
    assert_raises(ForumPhotoAttachments::NotAllowed) { attach([ "100" ], topic: @other_topic) }
    assert_equal @topic.id, Photo.find(100).topic_id
  end

  def test_guest_locked_blocked_and_unreadable_topic_access_is_denied
    assert_raises(ForumPhotoAttachments::NotAllowed) { attach([ "100" ], user: nil) }
    @topic.update!(locked: true)
    assert_raises(ForumPhotoAttachments::NotAllowed) { attach([ "100" ]) }
    @topic.update!(locked: false, moderation_state: :blocked)
    assert_raises(ForumPhotoAttachments::NotAllowed) { attach([ "100" ]) }
    @topic.update!(moderation_state: :approved)
    @user.define_singleton_method(:thredded_can_read_messageboard?) { |_board| false }
    assert_raises(ForumPhotoAttachments::NotAllowed) { attach([ "100" ]) }
    assert_nil Photo.find(100).topic_id
  end

  def test_malformed_selections_are_rejected
    [ [ "1 OR 1=1" ], { "id" => "100" }, [ "0" ], [ "-1" ], [ "100" ] * 51 ].each do |ids|
      assert_raises(ForumPhotoAttachments::NotAllowed) { attach(ids) }
    end
  end

  def test_article_post_and_attachments_commit_or_roll_back_together
    assert_raises(ForumPhotoAttachments::NotAllowed) do
      ArticleComment.create!(article: @article, user: @user, content: "Photo comment", photo_ids: [ "100", "101" ])
    end
    assert_nil @article.reload_topic
    assert_nil Photo.find(100).topic_id
    assert_equal 0, Thredded::Post.count
    assert_empty ActiveJob::Base.queue_adapter.enqueued_jobs
    post = ArticleComment.create!(article: @article, user: @user, content: "**My photo**\n\n[[photo=100]]", photo_ids: [ "100" ])
    assert_equal post.postable, Photo.find(100).parent_topic
    assert_equal 1, @article.reload.total_comments
    html = post.filtered_content(controller(ForumPhotosController).view_context)
    assert_includes html, "Photo 100"
    assert_includes html, "<strong>My photo</strong>"
    refute_includes html, "[[photo="
  end

  def test_topic_deletion_unlinks_photos_without_deleting_them
    attach([ "100" ])
    @topic.destroy!
    assert Photo.exists?(100)
    assert_nil Photo.find(100).topic_id
  end

  def test_picker_lists_only_eligible_photos_and_searches_places
    response = dispatch(ForumPhotosController, :index, topic_id: @topic.id)
    assert_equal 200, response.status
    assert_equal [ 100 ], JSON.parse(response.body).fetch("photos").map { |photo| photo.fetch("id") }
    response = dispatch(ForumPhotosController, :places, topic_id: @topic.id, search: "Moun")
    assert_equal [ { "id" => 70, "name" => "Mountain" } ], JSON.parse(response.body)
    @topic.update!(locked: true)
    assert_equal 403, dispatch(ForumPhotosController, :index, topic_id: @topic.id).status
  end

  def test_upload_uses_current_user_and_does_not_trust_attachment_fields
    file = Tempfile.new([ "forum-photo", ".png" ])
    file.binmode
    file.write(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII="))
    file.rewind
    upload = ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: "mountain.png", type: "image/png")
    response = dispatch(ForumPhotosController, :create, topic_id: @topic.id, place_id: 70, file: upload,
      user_id: 10, photo: { topic_id: @other_topic.id, user_id: 10 })
    assert_equal 201, response.status, response.body
    photo = Photo.find(JSON.parse(response.body).fetch("id"))
    assert_equal @user, photo.user
    assert_nil photo.topic_id
    assert photo.photo.attached?
    assert_equal 51, photo.ref_latitude
    assert_equal "Mountain", photo.ref_title
    attach([ photo.id.to_s ])
    assert_equal @topic, photo.reload.parent_topic
  ensure
    file&.close!
  end

  def test_generic_photo_params_cannot_assign_a_topic_and_thumb_edits_require_ownership
    instance = controller(PhotosController)
    instance.params = ActionController::Parameters.new(photo: { title: "Allowed", topic_id: @other_topic.id })
    refute instance.send(:photo_params).key?(:topic_id)
    assert_raises(ActiveRecord::RecordNotFound) do
      dispatch(PhotosController, :thumb_update, id: 101, title: "Stolen")
    end
    assert_equal "Photo 101", Photo.find(101).title
  end

  def test_picker_requires_login_and_new_topic_board_permissions
    assert_equal 403, dispatch(ForumPhotosController, :index, user: nil, topic_id: @topic.id).status
    assert_equal 200, dispatch(ForumPhotosController, :index, messageboard_id: @board.id).status
    @board.update!(locked: true)
    assert_equal 403, dispatch(ForumPhotosController, :index, messageboard_id: @board.id).status
  end

  def test_nonimage_upload_is_rejected_without_creating_a_photo
    file = Tempfile.new([ "not-image", ".txt" ])
    file.write("not an image")
    file.rewind
    upload = ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: "text.txt", type: "text/plain")
    count = Photo.count
    response = dispatch(ForumPhotosController, :create, messageboard_id: @board.id, place_id: 70, file: upload)
    assert_equal 422, response.status
    assert_equal count, Photo.count
  ensure
    file&.close!
  end

  def test_thredded_topic_creation_and_reply_updates_attach_atomically
    response = dispatch(Thredded::TopicsController, :create, messageboard_id: @board.slug,
      topic: { title: "New photo topic", content: "[[photo=100]]" }, forum_photo_ids: [ "100", "101" ])
    assert_equal 422, response.status
    assert_equal 2, Thredded::Topic.count
    assert_equal 0, Thredded::Post.count
    assert_nil Photo.find(100).topic_id
    assert_nil response.headers["Location"]

    response = dispatch(Thredded::TopicsController, :create, messageboard_id: @board.slug,
      topic: { title: "New photo topic", content: "[[photo=100]]" }, forum_photo_ids: [ "100" ])
    assert_equal 302, response.status
    assert_equal 3, Thredded::Topic.count, Thredded::Topic.pluck(:id, :title).inspect
    post = Thredded::Post.first
    assert_equal post.postable_id, Photo.find(100).topic_id

    response = dispatch(Thredded::PostsController, :update, messageboard_id: @board.slug,
      topic_id: post.postable.slug, id: post.id, post: { content: "Should roll back" }, forum_photo_ids: [ "101" ])
    assert_equal 422, response.status
    assert_equal "[[photo=100]]", post.reload.content

    response = dispatch(Thredded::PostsController, :create, messageboard_id: @board.slug,
      topic_id: post.postable.slug, post: { content: "Another reply" }, forum_photo_ids: [ "100" ])
    assert_equal 302, response.status
    assert_equal 2, Thredded::Post.count
  end

  def test_concurrent_claims_cannot_move_another_topics_attachment
    ready = Queue.new
    start = Queue.new
    threads = [ @topic.id, @other_topic.id ].map do |topic_id|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          old_path = connection.schema_search_path
          connection.schema_search_path = "#{@schema}, public"
          ready << true
          start.pop
          begin
            ForumPhotoAttachments.attach!(topic: Thredded::Topic.find(topic_id), user: User.find(11), photo_ids: [ "100" ])
            :attached
          rescue ForumPhotoAttachments::NotAllowed
            :refused
          end
        ensure
          connection.schema_search_path = old_path
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    assert_equal [ :attached, :refused ], threads.map(&:value).sort
    assert_includes [ @topic.id, @other_topic.id ], Photo.find(100).topic_id
  end

  private

  def controller(klass, user: @user)
    instance = klass.new
    request_user = User.find(user.id) if user
    request = ActionController::TestRequest.create(klass)
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["warden"] = Warden::Proxy.new(request.env, Warden::Manager.new(nil))
    request.env["warden"].set_user(request_user, scope: :user, store: false) if request_user
    instance.set_request!(request)
    instance.set_response!(ActionDispatch::TestResponse.new)
    instance.define_singleton_method(:current_user) { @test_user }
    instance.instance_variable_set(:@test_user, request_user)
    instance
  end

  def dispatch(klass, action, user: @user, **params)
    instance = controller(klass, user: user)
    instance.request.path_parameters = { controller: klass.controller_path, action: action.to_s }
    instance.request.set_header("REQUEST_METHOD", [ :index, :places ].include?(action) ? "GET" : "POST")
    instance.request.set_header("action_dispatch.request.request_parameters", params.stringify_keys)
    instance.dispatch(action, instance.request, instance.response)
    instance.response
  end
end
