ENV["RAILS_ENV"] = "test"
require_relative "../../config/environment"
require "minitest/autorun"
require "action_dispatch/testing/integration"
require "action_controller/test_case"
require_relative "../support/forum_database"

class ForumIntegrationTest < Minitest::Test
  include ForumDatabase

  def run
    Rails.application.executor.wrap { super }
  end

  def setup
    super
    @session = ActionDispatch::Integration::Session.new(Rails.application)
  end

  def get(path)
    ActiveRecord::Base.lease_connection.schema_search_path = "#{@schema}, public"
    @session.get(path, headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 Chrome/130.0.0.0 Safari/537.36" })
    @session.response
  end

  def topic(title, state: :approved, time: Time.current, replies: 0)
    record = Thredded::Topic.create!(title: title, user: @user, messageboard: @board, moderation_state: state)
    (replies + 1).times do
      Thredded::Post.create!(postable: record, messageboard: @board, user: @user,
        content: "Discussion content", moderation_state: :approved, created_at: time)
    end
    record
  end

  def test_lists_and_search_apply_moderation_and_time_filters
    topic("Recent unanswered")
    topic("Answered discussion", replies: 1)
    topic("Old discussion", time: 121.days.ago)
    topic("Pending secret", state: :pending_moderation)
    topic("Blocked secret", state: :blocked)
    response = get("/fanaticsforum/active_topics")
    assert_equal 200, response.status
    assert_equal "noindex", response.headers["X-Robots-Tag"]
    assert_includes response.body, "Recent unanswered"
    assert_includes response.body, "Answered discussion"
    [ "Old discussion", "Pending secret", "Blocked secret" ].each { |title| refute_includes response.body, title }
    response = get("/fanaticsforum/unanswered")
    assert_equal 200, response.status
    assert_includes response.body, "Recent unanswered"
    [ "Answered discussion", "Old discussion", "Pending secret", "Blocked secret" ].each { |title| refute_includes response.body, title }
    response = get("/fanaticsforum/?q=discussion")
    assert_equal 200, response.status
    assert_includes response.body, "Answered discussion"
    refute_includes response.body, "Blocked secret"
    refute_includes response.body, "Pending secret"
  end

  def test_custom_lists_exclude_unreadable_boards
    topic("Restricted discussion")
    viewer = User.find(11)
    viewer.define_singleton_method(:thredded_can_read_messageboards) { Thredded::Messageboard.none }
    instance = ForumTopicsController.new
    request = ActionController::TestRequest.create(ForumTopicsController)
    request.path_parameters = { controller: "forum_topics", action: "active", messageboard_id: @board.slug }
    instance.set_request!(request)
    instance.set_response!(ActionDispatch::TestResponse.new)
    instance.define_singleton_method(:current_user) { viewer }
    instance.dispatch(:active, request, instance.response)
    assert_equal 200, instance.response.status
    refute_includes instance.response.body, "Restricted discussion"
  end

  def test_active_list_paginates_and_navigation_omits_unreadable_boards
    now = Time.current
    Thredded::Topic.insert_all!(31.times.map do |index|
      { title: "Paginated discussion #{index}", slug: "paginated-#{index}", hash_id: "hash-#{index}",
        messageboard_id: @board.id, user_id: @user.id, last_post_at: now,
        created_at: now, updated_at: now, moderation_state: 1 }
    end)
    response = get("/fanaticsforum/active_topics?page=2")
    assert_equal 200, response.status
    assert_includes response.body, "Paginated discussion 0"
    refute_includes response.body, "Paginated discussion 30"

    viewer = User.find(11)
    viewer.define_singleton_method(:thredded_can_read_messageboards) { Thredded::Messageboard.none }
    controller = ApplicationController.new
    controller.set_request!(ActionController::TestRequest.create(ApplicationController))
    view = controller.view_context
    view.define_singleton_method(:current_user) { viewer }
    assert_empty view.forum_navigation_groups
    assert_equal "/fanaticsforum/", view.forum_suggestions_path
  end

  def test_legacy_search_and_list_links_have_usable_destinations
    response = get("/fanaticsforum/search?search=mountain+trail&sort=invalid&host=evil.test")
    assert_equal 302, response.status
    assert_equal "http://www.example.com/fanaticsforum/?q=mountain+trail", response.location
    assert_equal "http://www.example.com/fanaticsforum/unanswered", get("/fanaticsforum/search?unanswered=true").location
    assert_equal "http://www.example.com/fanaticsforum/active_topics", get("/fanaticsforum/search?hours=6").location
    ActiveRecord::Base.lease_connection.schema_search_path = "#{@schema}, public"
    @board.update!(forem_forum_id: 999)
    assert_equal "http://www.example.com/fanaticsforum/#{@board.slug}", get("/fanaticsforum/list_topics?forum_id=999&sort=invalid").location
  end

  def test_geographic_and_user_associations_use_explicit_mapping
    @board.update!(forem_forum_id: 999)
    Place.insert_all!([ { id: 70, type: "Place", name: "Area", partial_name_match: false,
      insert_id: 10, forum_id: 999, area: 1 } ])
    Route.insert_all!([ { id: 50, type: "Route", name: "Trail", travel_time: "", insert_id: 10 } ])
    route = Route.find(50)
    assert_equal @board, route.forum
    assert_equal @board, Place.find(70).forum
    PlaceRouteInArea.insert_all!([ { place_id: 70, route_id: 50 } ])
    assert_equal @board, route.forum
    Place.where(id: 70).update_all(forum_id: 998)
    assert_nil route.forum
    assert_nil Place.find(70).forum
    record = topic("User discussion")
    assert_equal [ record.id ], @user.topics.pluck(:id)
    assert_equal record.posts.pluck(:id), @user.posts.pluck(:id)
    assert_equal "forem_views", @user.forem_views.klass.table_name
  end

  def test_site_menu_and_notification_links_use_thredded
    @board.update!(forem_forum_id: 21, forem_slug: "suggestions")
    record = topic("Article discussion")
    record.update!(album: @article)
    response = get("/listing")
    assert_equal 200, response.status
    assert_includes response.body, 'href="/fanaticsforum/"'
    response = get("/contributions")
    assert_equal 200, response.status
    assert_includes response.body, "/fanaticsforum/active_topics"
    assert_includes response.body, "/fanaticsforum/#{@board.slug}"
    refute_includes response.body, "/fanaticsforum/forums/"
    mail = UserMailer.article_first_comment("album", @article.reload)
    assert_includes mail.body.encoded, "/fanaticsforum/#{@board.slug}/#{record.slug}"
    assert_includes mail.body.encoded, "/#{record.slug}/unfollow"
  end
end
