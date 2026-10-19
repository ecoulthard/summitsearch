ENV["RAILS_ENV"] = "test"
require_relative "../../config/environment"
require "minitest/autorun"
require "action_dispatch/testing/integration"
require_relative "../support/forum_database"

class ForumRoutesTest < Minitest::Test
  include ForumDatabase

  # Keep the isolated schema connection leased across simulated requests.
  def run
    Rails.application.executor.wrap { super }
  end

  def setup
    super
    @board.update!(forem_forum_id: 90, forem_slug: "old-board")
    @topic = Thredded::Topic.create!(title: "Migrated discussion", user: @user, messageboard: @board,
      forem_topic_id: 91, forem_slug: "old-topic", moderation_state: :approved)
    # Identical timestamps exercise the ID tie-breaker across a page boundary.
    timestamp = 1.day.ago.change(usec: 0)
    (Thredded.posts_per_page + 1).times do |index|
      @post = Thredded::Post.create!(postable: @topic, messageboard: @board, user: @user,
        content: "Visible reply #{index}", moderation_state: :approved,
        created_at: timestamp, forem_post_id: 1000 + index)
    end
    @session = ActionDispatch::Integration::Session.new(Rails.application)
  end

  def get(path)
    ActiveRecord::Base.lease_connection.schema_search_path = "#{@schema}, public"
    @session.get(path, headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 Chrome/130.0.0.0 Safari/537.36" })
    @session.response
  end

  def test_numeric_slug_and_historical_nested_urls
    [ "90", "old-board" ].product([ "91", "old-topic" ]).each do |board, topic|
      response = get("/fanaticsforum/forums/#{board}/topics/#{topic}?host=evil.test&page=999")
      assert_equal 301, response.status
      assert_equal "http://www.example.com/fanaticsforum/#{@board.slug}/#{@topic.slug}", response.location
    end
    FriendlyId::Slug.insert_all!([ { sluggable_type: "Forem::Forum", sluggable_id: 90, slug: "older-board" } ])
    FriendlyId::Slug.insert_all!([ { sluggable_type: "Forem::Topic", sluggable_id: 91, slug: "older-topic", scope: "forum_id:90" } ])
    assert_equal 301, get("/fanaticsforum/forums/older-board/topics/older-topic").status
    assert_equal 301, get("/fanaticsforum/forums/90").status
    assert_equal 301, get("/fanaticsforum/forums").status
    other = Thredded::Messageboard.create!(name: "Unrelated", forem_forum_id: 92)
    assert_equal 404, get("/fanaticsforum/forums/#{other.forem_forum_id}/topics/91").status
    assert_equal 404, get("/fanaticsforum/forums/unknown").status
    assert_equal 404, get("/fanaticsforum/forums/#{@board.id}").status
    assert_equal 404, get("/fanaticsforum/forums/90/topics/91/posts/unknown").status
    assert_equal 404, get("/fanaticsforum/forums/90/topics/91/posts/999999").status
    group = Thredded::MessageboardGroup.create!(name: "Regional forums", forem_category_id: 80, forem_slug: "old-category")
    [ "80", "old-category" ].each do |category|
      response = get("/fanaticsforum/categories/#{category}")
      assert_equal 301, response.status
      assert_equal "http://www.example.com/fanaticsforum/messageboard-groups/#{group.id}", response.location
    end
  end

  def test_post_redirect_uses_permalink_and_reaches_correct_page_and_anchor
    response = get("/fanaticsforum/forums/90/topics/91/posts/#{@post.forem_post_id}")
    assert_equal 301, response.status
    assert_equal "http://www.example.com/fanaticsforum/posts/#{@post.id}", response.location
    response = get(URI(response.location).request_uri)
    assert_equal 302, response.status
    assert_includes response.location, "/page-2#post_#{@post.id}"
    response = get(URI(response.location).request_uri)
    assert_equal 200, response.status, response.body[0, 500]
    assert_includes response.body, "id=\"post_#{@post.id}\""
    assert_includes response.body, "Visible reply #{Thredded.posts_per_page}"
    refute_includes response.body, "Visible reply 0<"

    # A guest's page excludes pending posts; the same last post now fits on page 1.
    @topic.posts.order_oldest_first.first.update_columns(moderation_state: 0)
    response = get("/fanaticsforum/posts/#{@post.id}")
    assert_equal 302, response.status
    refute_includes response.location, "/page-2"
    assert_includes response.location, "#post_#{@post.id}"
  end

  def test_mounted_index_board_and_topic_and_visibility
    [ "/fanaticsforum", "/fanaticsforum/#{@board.slug}", "/fanaticsforum/#{@board.slug}/#{@topic.slug}" ].each do |path|
      response = get(path)
      assert_equal 200, response.status, response.body[0, 500]
      assert_includes response.body, "thredded"
    end
    ActiveRecord::Base.lease_connection.schema_search_path = "#{@schema}, public"
    @post.update!(moderation_state: :blocked, content: "Secret blocked reply")
    response = get("/fanaticsforum/posts/#{@post.id}")
    refute_equal 302, response.status
    refute_includes response.body, "Secret blocked reply"
    response = get("/fanaticsforum/#{@board.slug}/#{@topic.slug}")
    assert_equal 200, response.status
    refute_includes response.body, "Secret blocked reply"
  end
end
